using StreamingTimeSeries
using Base.Test

# EMAFeature
f = EMAFeature(1.0, DateTime(), 0.0, 0.0)
@test valueat(f, DateTime(2015,8,7)) == 0.0
update!(f, DateTime(4050,12,1,1,1,1), 1.0)
@test abs(valueat(f, DateTime(2015,8,7)) - 1.0) < 0.00001
update!(f, DateTime(4050,12,1,1,1,1), 1.0)
@test abs(valueat(f, DateTime(2015,8,7)) - 1.0) < 0.00001

# TimeSinceFeature
f = TimeSinceFeature(DateTime(2015,8,7,1,1,1))
@test valueat(f, DateTime(2015,8,7,1,1,1)) == 0.0
update!(f, DateTime(2015,8,7,2,1,1))
@test valueat(f, DateTime(2015,8,7,2,1,1)) == 0.0
@test valueat(f, DateTime(2015,8,7,2,3,1)) == 2.0
@test valueat(f, DateTime(2014,8,7,2,3,1)) == 0.0

# LastValueFeature
f = LastValueFeature(DateTime(2015,8,7), 1.4)
@test valueat(f, DateTime(2015,8,6)) == 0
@test valueat(f, DateTime(2015,8,7)) == 1.4
@test valueat(f, DateTime(2015,8,8)) == 1.4
