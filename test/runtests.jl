using StreamingTimeSeries
using Base.Test

# EMAFeature
f = EMAFeature(1)
@test valueat(f, DateTime(2015,8,7)) == 0.0
update!(f, DateTime(2014,12,1,1,1,1), 1.0)
@test abs(valueat(f, DateTime(2015,8,7)) - 1.0) < 0.00001
update!(f, DateTime(2014,12,1,1,1,1), 1.0)
@test abs(valueat(f, DateTime(2015,8,7)) - 1.0) < 0.00001

# EMVFeature
f = EMVFeature(2)
@test valueat(f, DateTime(2015,8,7)) == 0.0
update!(f, DateTime(2015,8,15,9,0,0), 1.0)
update!(f, DateTime(2015,8,15,10,0,0), 10.0)
update!(f, DateTime(2015,8,15,11,0,0), 1.0)
update!(f, DateTime(2015,8,15,12,0,0), 10.0)
@test valueat(f, DateTime(2015,8,15,12,0,0)) > 0.1
update!(f, DateTime(2015,8,15,12,0,0), 2.0)
update!(f, DateTime(2015,8,15,13,0,0), 2.0)
update!(f, DateTime(2015,8,15,14,0,0), 2.0)
update!(f, DateTime(2015,8,15,15,0,0), 2.0)
update!(f, DateTime(2015,8,15,16,0,0), 2.0)
update!(f, DateTime(2015,8,15,17,0,0), 2.0)
update!(f, DateTime(2015,8,15,18,0,0), 2.0)
@test valueat(f, DateTime(2015,8,15,18,0,0)) < 0.1

# TimeSinceFeature
f = TimeSinceFeature(DateTime(2015,8,7,1,1,1))
@test valueat(f, DateTime(2015,8,7,1,1,1)) == 0.0
update!(f, DateTime(2015,8,7,2,1,1))
@test valueat(f, DateTime(2015,8,7,2,1,1)) == 0.0
@test valueat(f, DateTime(2015,8,7,2,3,1)) == 2.0
@test valueat(f, DateTime(2014,8,7,2,3,1)) == 0.0
f = TimeSinceFeature()
update!(f, DateTime(2015,8,7,2,1,1))
@test valueat(f, DateTime(2015,8,7,2,1,1)) == 0.0
@test valueat(f, DateTime(2015,8,7,2,3,1)) == 2.0

# LastValueFeature
f = LastValueFeature(DateTime(2015,8,7), 1.4)
@test valueat(f, DateTime(2015,8,6)) == 0
@test valueat(f, DateTime(2015,8,7)) == 1.4
@test valueat(f, DateTime(2015,8,8)) == 1.4
f = LastValueFeature()
@test valueat(f, DateTime(2015,8,6)) == 0

# DecayFeature
f = DecayFeature(1)
@test valueat(f, DateTime(2015,8,7)) == 0.0
update!(f, DateTime(2014,12,1,1,1,1), 1.0)
@test valueat(f, DateTime(2015,8,7)) < 0.00001
update!(f, DateTime(2014,12,1,1,1,1), 1.0)
@test abs(valueat(f, DateTime(2014,12,1,1,2,1)) - 1) < 0.00001
