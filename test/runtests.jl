using StreamingTimeSeries
using Base.Test
using Dates

# write your own tests here
f = EMAFeature(1.0, DateTime(), 0.0, 0.0)
@test value(f) == 0.0
update!(f, DateTime(4050,12,1,1,1,1), 1.0)
@test abs(value(f) - 1.0) < 0.00001
update!(f, DateTime(4050,12,1,1,1,1), 1.0)
@test abs(value(f) - 1.0) < 0.00001
