module StreamingTimeSeries

import Base.Dates.TimeType

export EMAFeature, EMVFeature, TimeSinceFeature, LastValueFeature, DecayFeature, LagSumFeature, update!, valueat

# see EMA_lin in http://www.eckner.com/papers/ts_alg.pdf
type EMAFeature{T<:TimeType}
    decayRate::Float64
    lastTime::T
    lastValue::Float64
    value::Float64
end
EMAFeature{T<:TimeType}(decayRate::Float64, lastTime::T) = EMAFeature(decayRate, lastTime, 0.0, 0.0)
function update!{T<:TimeType}(feature::EMAFeature{T}, time::T, value::Float64)
    @assert time >= feature.lastTime
    if time == feature.lastTime
        return feature.value
    end

    dt = Float64(time - feature.lastTime)/60000 # convert from milliseconds to minutes
    a = dt / feature.decayRate
    u = exp(-a)
    v = (1 - u) / a
    feature.value = u*feature.value + (v - u)*feature.lastValue + (1.0 - v)*value
    feature.lastTime = time
    feature.lastValue = value

    feature.value
end
function valueat{T<:TimeType}(feature::EMAFeature{T}, time::T)
    @assert time >= feature.lastTime
    feature.value
end

type EMVFeature{T<:TimeType}
    ema::EMAFeature{T}
    ema2::EMAFeature{T}
    value::Float64
end
EMVFeature{T<:TimeType}(decayRate::Float64, lastTime::T) = EMVFeature(EMAFeature(decayRate, lastTime), EMAFeature(decayRate, lastTime), 0.0)
function update!{T<:TimeType}(feature::EMVFeature{T}, time::T, value::Float64)
    @assert time >= feature.ema.lastTime
    if time == feature.ema.lastTime
        return feature.value
    end

    update!(feature.ema, time, value)
    update!(feature.ema2, time, value^2)

    feature.value = feature.ema2.value - feature.ema.value^2
end
function valueat{T<:TimeType}(feature::EMVFeature{T}, time::T)
    @assert time >= feature.ema.lastTime
    feature.value
end

# simply keep track of how far we are from the reference time point
# note that we collapse all negative values to 0.0 since otherwise they
# would provide information about the future.
type TimeSinceFeature{T<:TimeType}
    referenceTime::T
end
function update!{T<:TimeType}(feature::TimeSinceFeature{T}, time::T)
    feature.referenceTime = time
end
function update!{T<:TimeType}(feature::TimeSinceFeature{T}, time::T, ignored::Float64)
    update!(feature, time)
end
function valueat{T<:TimeType}(feature::TimeSinceFeature{T}, time::T)
    numMin = Float64(time - feature.referenceTime)/60000 # convert from milliseconds to minutes
    numMin < 0.0 ? 0.0 : numMin
end

# simply keep track of the last value seen
type LastValueFeature{T<:TimeType}
    time::T
    value::Float64
end
LastValueFeature{T<:TimeType}(time::T) = LastValueFeature(time, 0.0)
function update!{T<:TimeType}(feature::LastValueFeature{T}, time::T, value::Float64)
    feature.time = time
    feature.value = value
end
function valueat{T<:TimeType}(feature::LastValueFeature{T}, time::T)
    time < feature.time ? 0.0 : feature.value
end


# Sum all the values and let them decay exponentially
type DecayFeature{T<:TimeType}
    decayRate::Float64
    lastTime::T
    value::Float64
end
DecayFeature{T<:TimeType}(halfLife::Float64, lastTime::T) = DecayFeature(exp(log(0.5)/halfLife), lastTime, 0.0)
function update!{T<:TimeType}(feature::DecayFeature{T}, time::T, value::Float64)
    @assert time >= feature.lastTime

    dt = Float64(time - feature.lastTime)/60000 # convert from milliseconds to minutes
    feature.lastTime = time
    feature.value *= feature.decayRate^dt
    feature.value += value
end
function valueat{T<:TimeType}(feature::DecayFeature{T}, time::T)
    @assert time >= feature.lastTime
    dt = Float64(time - feature.lastTime)/60000 # convert from milliseconds to minutes
    feature.value * feature.decayRate^dt
end

"Sum all the values in a window, the starting point is excluded and the end point included."
type LagSumFeature{T<:TimeType}
    lagStart::Dates.TimePeriod # exclusive
    lagEnd::Dates.TimePeriod # inclusive
    bufferTimes::Array{T,1}
    bufferValues::Array{Float64,1}
    windowTimes::Array{T,1}
    windowValues::Array{Float64,1}
    lastTime::T
    value::Float64
end
LagSumFeature{T<:TimeType}(lagStart::Dates.TimePeriod, lagEnd::Dates.TimePeriod, lastTime::T) = LagSumFeature(lagStart, lagEnd, T[], Float64[], T[], Float64[], lastTime, 0.0)
function update!{T<:TimeType}(feature::LagSumFeature{T}, time::T, value::Float64)
    @assert time >= feature.lastTime
    feature.lastTime = time
    unshift!(feature.bufferTimes, time)
    unshift!(feature.bufferValues, value)
end
function valueat{T<:TimeType}(feature::LagSumFeature{T}, time::T)
    @assert time >= feature.lastTime

    # move data from the buffer to the window
    for i in length(feature.bufferTimes):-1:1
        if time - feature.bufferTimes[i] >= feature.lagEnd
            unshift!(feature.windowTimes, pop!(feature.bufferTimes))
            unshift!(feature.windowValues, pop!(feature.bufferValues))
            feature.value += feature.windowValues[1]
        else
            break
        end
    end

    # move data out of the window
    for i in length(feature.windowTimes):-1:1
        if time - feature.windowTimes[i] >= feature.lagStart
            pop!(feature.windowTimes)
            feature.value -= pop!(feature.windowValues)
        else
            break
        end
    end
    feature.lastTime = time

    feature.value
end

end # module
