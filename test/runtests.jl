using StreamingTimeSeries
using Base.Test
using TimeZones

# EMAFeature
f = EMAFeature(1.0, DateTime())
@test valueat(f, DateTime(2015,8,7)) == 0.0
update!(f, DateTime(2014,12,1,1,1,1), 1.0)
@test abs(valueat(f, DateTime(2015,8,7)) - 1.0) < 0.00001
update!(f, DateTime(2014,12,1,1,1,1), 1.0)
@test abs(valueat(f, DateTime(2015,8,7)) - 1.0) < 0.00001

f = EMAFeature(1.0, ZonedDateTime(DateTime(), TimeZone("UTC")))
@test valueat(f, ZonedDateTime(DateTime(2015,8,7), TimeZone("UTC"))) == 0.0
update!(f, ZonedDateTime(DateTime(2014,12,1,1,1,1), TimeZone("UTC")), 1.0)
@test abs(valueat(f, ZonedDateTime(DateTime(2015,8,7), TimeZone("UTC"))) - 1.0) < 0.00001
update!(f, ZonedDateTime(DateTime(2014,12,1,1,1,1), TimeZone("UTC")), 1.0)
@test abs(valueat(f, ZonedDateTime(DateTime(2015,8,7), TimeZone("UTC"))) - 1.0) < 0.00001

# EMVFeature
f = EMVFeature(2.0, DateTime())
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
f = TimeSinceFeature(DateTime())
update!(f, DateTime(2015,8,7,2,1,1))
@test valueat(f, DateTime(2015,8,7,2,1,1)) == 0.0
@test valueat(f, DateTime(2015,8,7,2,3,1)) == 2.0

# LastValueFeature
f = LastValueFeature(DateTime(2015,8,7), 1.4)
@test valueat(f, DateTime(2015,8,6)) == 0
@test valueat(f, DateTime(2015,8,7)) == 1.4
@test valueat(f, DateTime(2015,8,8)) == 1.4
f = LastValueFeature(DateTime())
@test valueat(f, DateTime(2015,8,6)) == 0

# DecayFeature
f = DecayFeature(1.0, DateTime())
@test valueat(f, DateTime(2015,8,7)) == 0.0
update!(f, DateTime(2014,12,1,1,1,1), 1.0)
@test valueat(f, DateTime(2015,8,7)) < 0.00001
update!(f, DateTime(2014,12,1,1,1,1), 1.0)
@test abs(valueat(f, DateTime(2014,12,1,1,2,1)) - 1) < 0.00001

# LagSumFeature
f = LagSumFeature(Dates.Minute(1), Dates.Minute(0), DateTime())
@test valueat(f, DateTime(2015,8,7)) == 0.0
update!(f, DateTime(2015,9,1,1,1,1), 1.0)
@test valueat(f, DateTime(2015,9,1,1,1,1)) == 1.0
update!(f, DateTime(2015,9,1,1,2,1), 1.0)
@test valueat(f, DateTime(2015,9,1,1,2,1)) == 1.0
@test valueat(f, DateTime(2015,9,1,1,3,1)) == 0.0

f = LagSumFeature(Dates.Minute(6), Dates.Minute(4), DateTime())
update!(f, DateTime(2015,9,1,1,1,1), 1.0)
update!(f, DateTime(2015,9,1,1,2,1), 1.0)
@test valueat(f, DateTime(2015,9,1,1,3,1)) == 0.0
@test valueat(f, DateTime(2015,9,1,1,5,1)) == 1.0
@test valueat(f, DateTime(2015,9,1,1,6,1)) == 2.0
@test valueat(f, DateTime(2015,9,1,1,7,1)) == 1.0
@test valueat(f, DateTime(2015,9,1,1,8,1)) == 0.0

# LagLastValueFeature
f = LagLastValueFeature(Dates.Second(1), DateTime())
@test valueat(f, DateTime(2015,8,7)) == 0.0
update!(f, DateTime(2015,9,1,1,1,1), 1.0)
@test valueat(f, DateTime(2015,9,1,1,1,1)) == 0.0
update!(f, DateTime(2015,9,1,1,1,2), 2.0)
@test valueat(f, DateTime(2015,9,1,1,1,2)) == 1.0
@test valueat(f, DateTime(2015,9,1,1,1,3)) == 2.0
@test valueat(f, DateTime(2015,9,1,1,1,4)) == 2.0
