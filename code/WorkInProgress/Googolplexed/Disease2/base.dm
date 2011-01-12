//To simplify, all diseases have 4 stages, with effects starting at stage 2
//Stage 1 = Rest,Minor disease
//Stage 2 = Minimal effect
//Stage 3 = Medium effect
//Stage 4 = Death/Really Really really bad effect


/proc/infect_virus2(var/mob/living/carbon/M,var/datum/disease2/disease/disease)
	if(prob(disease.infectionchance))
		if(M.virus2)
			return
		else
			var/score = 0
			if(istype(M, /mob/living/carbon/human))
				if(M:gloves)
					score += 5
				if(istype(M:wear_suit, /obj/item/clothing/suit/space)) score += 10
				if(istype(M:wear_suit, /obj/item/clothing/suit/bio_suit)) score += 10
				if(istype(M:wear_suit, /obj/item/clothing/head/helmet/space)) score += 5
				if(istype(M:head, /obj/item/clothing/head/bio_hood)) score += 5
			if(M.wear_mask)
				score += 5
				if((istype(M:wear_mask, /obj/item/clothing/mask) || istype(M:wear_mask, /obj/item/clothing/mask/surgical)) && !M.internal)
					score += 5
				if(M.internal)
					score += 5
			if(score > 20)
				return
			else if(score == 20 && prob(95))
				return
			else if(score == 15 && prob(75))
				return
			else if(score == 10 && prob(55))
				return
			else if(score == 5 && prob(35))
				return

			M.virus2 = disease.getcopy()
			M.virus2.minormutate()

			for(var/datum/disease2/resistance/res in M.resistances)
				if(res.resistsdisease(M.virus2))
					M.virus2 = null



/datum/disease2/resistance
	var/list/datum/disease2/effect/resistances = list()

	proc/resistsdisease(var/datum/disease2/disease/virus2)
		var/list/res2 = list()
		for(var/datum/disease2/effect/e in resistances)
			res2 += e.type
		for(var/datum/disease2/effectholder/holder in virus2)
			if(!(holder.effect.type in res2))
				return 0
			else
				res2 -= holder.effect.type
		if(res2.len > 0)
			return 0
		else
			return 1

	New(var/datum/disease2/disease/virus2)
		for(var/datum/disease2/effectholder/h in virus2.effects)
			resistances += h.effect.type


/proc/infect_mob_random(var/mob/living/carbon/M)
	if(!M.virus2)
		M.virus2 = new /datum/disease2/disease
		M.virus2.makerandom()

/datum/disease2/disease
	var/infectionchance = 10
	var/spreadtype = "Blood" // Can also be "Airborne"
	var/stage = 1
	var/stageprob = 7
	var/dead = 0
	var/clicks = 0

	var/uniqueID = 0
	var/list/datum/disease2/effectholder/effects = list()
	proc/makerandom()
		var/datum/disease2/effectholder/holder = new /datum/disease2/effectholder
		holder.stage = 1
		holder.getrandomeffect()
		effects += holder
		holder = new /datum/disease2/effectholder
		holder.stage = 2
		holder.getrandomeffect()
		effects += holder
		holder = new /datum/disease2/effectholder
		holder.stage = 3
		holder.getrandomeffect()
		effects += holder
		holder = new /datum/disease2/effectholder
		holder.stage = 4
		holder.getrandomeffect()
		effects += holder
		uniqueID = rand(0,10000)
		infectionchance = rand(1,5)
		spreadtype = "Airborne"
	proc/minormutate()
		var/datum/disease2/effectholder/holder = pick(effects)
		holder.minormutate()
		infectionchance = min(50,infectionchance + rand(-2,5))
	proc/issame(var/datum/disease2/disease/disease)
		var/list/types = list()
		var/list/types2 = list()
		for(var/datum/disease2/effectholder/d in effects)
			types += d.effect.type
		var/equal = 1

		for(var/datum/disease2/effectholder/d in disease.effects)
			types2 += d.effect.type

		for(var/type in types)
			if(!(type in types2))
				equal = 0
		return equal

	proc/activate(var/mob/living/carbon/mob)
		if(dead)
			mob.virus2 = null
			return
		if(mob.stat == 2)
			return
		if(prob(stageprob) && prob(25 + (clicks/25)) && stage != 4)
			stage++
			clicks = 0
		for(var/datum/disease2/effectholder/e in effects)
			e.runeffect(mob,stage)

	proc/cure_added(var/datum/disease2/resistance/res)
		if(res.resistsdisease(src))
			dead = 1


	proc/getcopy()
//		world << "getting copy"
		var/datum/disease2/disease/disease = new /datum/disease2/disease
		disease.infectionchance = infectionchance
		disease.spreadtype = spreadtype
		disease.stageprob = stageprob
		for(var/datum/disease2/effectholder/holder in effects)
	//		world << "adding effects"
			var/datum/disease2/effectholder/newholder = new /datum/disease2/effectholder
			newholder.effect = new holder.effect.type
			newholder.chance = holder.chance
			newholder.cure = holder.cure
			newholder.multiplyer = holder.multiplyer
			newholder.happensonce = holder.happensonce
			newholder.stage = holder.stage
			disease.effects += newholder
	//		world << "[newholder.effect.name]"
	//	world << "[disease]"
		return disease

/datum/disease2/effect
	var/name = "Blanking effect"
	var/stage = 4
	var/maxm = 1
	proc/activate(var/mob/living/carbon/mob,var/multiplyer)

/datum/disease2/effect/gibbingtons
	name = "Gibbingtons Syndrome"
	stage = 4
	activate(var/mob/living/carbon/mob,var/multiplyer)
		mob.gib()

/datum/disease2/effect/radian
	name = "Radian's syndrome"
	stage = 4
	maxm = 3
	activate(var/mob/living/carbon/mob,var/multiplyer)
		mob.radiation += (2*multiplyer)

/datum/disease2/effect/toxins
	name = "Hyperacid Syndrome"
	stage = 3
	maxm = 3
	activate(var/mob/living/carbon/mob,var/multiplyer)
		mob.toxloss += (2*multiplyer)

/datum/disease2/effect/scream
	name = "Random screaming syndrome"
	stage = 2
	activate(var/mob/living/carbon/mob,var/multiplyer)
		mob.say("*scream")

/datum/disease2/effect/drowsness
	name = "Automated sleeping syndrome"
	stage = 2
	activate(var/mob/living/carbon/mob,var/multiplyer)
		mob.drowsyness += 10

/datum/disease2/effect/shakey
	name = "World Shaking syndrome"
	stage = 3
	maxm = 3
	activate(var/mob/living/carbon/mob,var/multiplyer)
		shake_camera(mob,5*multiplyer)

/datum/disease2/effect/deaf
	name = "Hard of hearing syndrome"
	stage = 4
	activate(var/mob/living/carbon/mob,var/multiplyer)
		mob.ear_deaf += 20


/datum/disease2/effect/sneeze
	name = "Coldingtons Effect"
	stage = 1
	activate(var/mob/living/carbon/mob,var/multiplyer)
		mob.say("*sneeze")
/datum/disease2/effect/sleepy
	name = "Resting syndrome"
	stage = 2
	activate(var/mob/living/carbon/mob,var/multiplyer)
		mob.say("*collapse")

/datum/disease2/effect/mind
	name = "Lazy mind syndrome"
	stage = 3
	activate(var/mob/living/carbon/mob,var/multiplyer)
		mob.brainloss = 50


/datum/disease2/effectholder
	var/name = "Holder"
	var/datum/disease2/effect/effect
	var/chance = 0 //Chance in percentage each tick
	var/cure = "" //Type of cure it requires
	var/happensonce = 0
	var/multiplyer = 1 //The chance the effects are WORSE
	var/stage = 0

	proc/runeffect(var/mob/living/carbon/human/mob,var/stage)
		if(happensonce > -1 && effect.stage <= stage && prob(chance))
			effect.activate(mob)
			if(happensonce == 1)
				happensonce = -1

	proc/getrandomeffect()
		var/list/datum/disease2/effect/list = list()
		for(var/e in (typesof(/datum/disease2/effect) - /datum/disease2/effect))
		//	world << "Making [e]"
			var/datum/disease2/effect/f = new e
			if(f.stage == src.stage)
				list += f
		effect = pick(list)
		chance = rand(1,6)

	proc/minormutate()
		switch(pick(1,2,3,4,5))
			if(1)
				chance = rand(0,100)
			if(2)
				multiplyer = rand(1,effect.maxm)
	proc/majormutate()
		getrandomeffect()

/proc/dprob(var/p)
	return(prob(sqrt(p)) && prob(sqrt(p)))