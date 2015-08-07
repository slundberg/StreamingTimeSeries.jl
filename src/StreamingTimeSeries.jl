module StreamingTimeSeries

using Dates

export EMAFeature, TimeSinceFeature, update!, valueat

# see EMA_lin in http://www.eckner.com/papers/ts_alg.pdf
type EMAFeature
    decayRate::Float64
    lastTime::DateTime
    lastValue::Float64
    value::Float64
end
function update!(feature::EMAFeature, time::DateTime, value::Float64)
    @assert time >= feature.lastTime
    if time == feature.lastTime
        return feature.value
    end

    dt = int(time - feature.lastTime)/60000 # convert from milliseconds to minutes
    a = dt / feature.decayRate
    u = exp(-a)
    v = (1 - u) / a
    feature.value = u*feature.value + (v - u)*feature.lastValue + (1.0 - v)*value
    feature.lastTime = time
    feature.lastValue = value

    feature.value
end
function valueat(feature::EMAFeature, time::DateTime)
    feature.value
end

# simply keep track of how far we are from the reference time point
type TimeSinceFeature
    referenceTime::DateTime
end
function update!(feature::TimeSinceFeature, time::DateTime)
    feature.referenceTime = time
end
function valueat(feature::TimeSinceFeature, time::DateTime)
    int(time - feature.referenceTime)/60000 # convert from milliseconds to minutes
end

end # module
