module StreamingTimeSeries

export EMAFeature, EMVFeature, TimeSinceFeature, LastValueFeature, DecayFeature, LagSumFeature, update!, valueat

# see EMA_lin in http://www.eckner.com/papers/ts_alg.pdf
type EMAFeature
    decayRate::Float64
    lastTime::DateTime
    lastValue::Float64
    value::Float64
end
EMAFeature(decayRate::Real) = EMAFeature(decayRate, DateTime(), 0.0, 0.0)
function update!(feature::EMAFeature, time::DateTime, value::Float64)
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
function valueat(feature::EMAFeature, time::DateTime)
    @assert time >= feature.lastTime
    feature.value
end

type EMVFeature
    ema::EMAFeature
    ema2::EMAFeature
    value::Float64
end
EMVFeature(decayRate::Real) = EMVFeature(EMAFeature(decayRate), EMAFeature(decayRate), 0.0)
function update!(feature::EMVFeature, time::DateTime, value::Float64)
    @assert time >= feature.ema.lastTime
    if time == feature.ema.lastTime
        return feature.value
    end

    update!(feature.ema, time, value)
    update!(feature.ema2, time, value^2)

    feature.value = feature.ema2.value - feature.ema.value^2
end
function valueat(feature::EMVFeature, time::DateTime)
    @assert time >= feature.ema.lastTime
    feature.value
end

# simply keep track of how far we are from the reference time point
# note that we collapse all negative values to 0.0 since otherwise they
# would provide information about the future.
type TimeSinceFeature
    referenceTime::DateTime
end
TimeSinceFeature() = TimeSinceFeature(DateTime(0,1,1,0,0,0))
function update!(feature::TimeSinceFeature, time::DateTime)
    feature.referenceTime = time
end
function update!(feature::TimeSinceFeature, time::DateTime, ignored::Float64)
    update!(feature, time)
end
function valueat(feature::TimeSinceFeature, time::DateTime)
    numMin = Float64(time - feature.referenceTime)/60000 # convert from milliseconds to minutes
    numMin < 0.0 ? 0.0 : numMin
end

# simply keep track of the last value seen
type LastValueFeature
    time::DateTime
    value::Float64
end
LastValueFeature() = LastValueFeature(DateTime(0,1,1,0,0,0), 0.0)
function update!(feature::LastValueFeature, time::DateTime, value::Float64)
    feature.time = time
    feature.value = value
end
function valueat(feature::LastValueFeature, time::DateTime)
    time < feature.time ? 0.0 : feature.value
end


# Sum all the values and let them decay exponentially
type DecayFeature
    decayRate::Float64
    lastTime::DateTime
    value::Float64
end
DecayFeature(halfLife::Real) = DecayFeature(exp(log(0.5)/halfLife), DateTime(), 0.0)
function update!(feature::DecayFeature, time::DateTime, value::Float64)
    @assert time >= feature.lastTime

    dt = Float64(time - feature.lastTime)/60000 # convert from milliseconds to minutes
    feature.lastTime = time
    feature.value *= feature.decayRate^dt
    feature.value += value
end
function valueat(feature::DecayFeature, time::DateTime)
    @assert time >= feature.lastTime
    dt = Float64(time - feature.lastTime)/60000 # convert from milliseconds to minutes
    feature.value * feature.decayRate^dt
end

"Sum all the values in a window, the starting point is excluded and the end point included."
type LagSumFeature
    lagStart::Dates.TimePeriod # exclusive
    lagEnd::Dates.TimePeriod # inclusive
    bufferTimes::Array{DateTime,1}
    bufferValues::Array{Float64,1}
    windowTimes::Array{DateTime,1}
    windowValues::Array{Float64,1}
    lastTime::DateTime
    value::Float64
end
LagSumFeature(lagStart::Dates.TimePeriod, lagEnd::Dates.TimePeriod) = LagSumFeature(lagStart, lagEnd, DateTime[], DateTime[], Float64[], Float64[], DateTime(), 0.0)
function update!(feature::LagSumFeature, time::DateTime, value::Float64)
    @assert time >= feature.lastTime
    feature.lastTime = time
    unshift!(feature.bufferTimes, time)
    unshift!(feature.bufferValues, value)
end
function valueat(feature::LagSumFeature, time::DateTime)
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
