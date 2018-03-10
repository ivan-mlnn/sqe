require './db.rb'
include Model
LEVEL_ID=69

game=Game[17]
level=Level[69]


def rnd
	v=Random.rand(10000000..999999999).to_s
	while DB[:codes].where(:level_id=>LEVEL_ID, v=>Sequel.pg_array(:code).any).count>0
		v=Random.rand(10000000..999999999).to_s
	end
	return v
end

def create_code(v,ko,main=true,time=0)

	number=  DB[:codes].where(:level_id=>LEVEL_ID).max(:number).to_i+1 
        sektor= 'Локация'
        code=Sequel.pg_array([v])
        bonus=time
        DB[:codes].insert(:level_id=>LEVEL_ID,:number=>number,:sektor=>sektor,:code=>code,:main=>main,:bonus=>bonus,:note=>'',:ko=>ko.strip,:hint=>'',:title=>'')
        
	
end
150.times { |n|

code=rnd
puts code
create_code(code,'2',true,60)

}

50.times { |n|

code=rnd
puts code
create_code(code,'3',true,300)

}