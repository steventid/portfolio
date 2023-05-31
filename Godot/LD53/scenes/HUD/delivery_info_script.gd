# UberHeck Game Loop
# Start splash 
# Start Menu
	# Start Menu has Controls, start game, credits, exit
		# Controls - Explainer text with "story", win condition, loss condition, and controls
		# credits - attributes and what not
	
	# Win condition - Get $500 in money. (seems a bit more realistic than 1,000)
	# Loss condition: Run out of gas or money? Text will appear to explain loss condition, 
	# and give option to Restart game, start menu, or exit.
	# Fall into lava - (All of this is nice to have, not necessary)
		# 1 second explosion animation
		# 1 second black screen with "Towing you out" text
		# 1 second respawn teleport - Put back on nearest road position with 20 less fuel and 20 less money, 
		# timer still going while on dispatch unless fuel or money = 0 as a result of lava swim (No more 
		# Than 3 seconds lost on timer should feel fair)
	
		
	# Start game 
		# show available text at top, start with full fuel and $50
			# player has control of taxi, can drive around while not on dispatch, will use fuel.
			# fuel station rings (separate from dispatches) will appear when fuel hits 50% 
			# can drive into to refuel 1/4 tank (25 pts) maybe $10 cost for that.
			# subtract cost from total
			# ring innactive after refuel, start "respawn timer" until it's able to be shown again.
			# prevents player from just camping one gas station
		# get order timer starts
			# rand order chosen
			# place location chosen
			# destination location chosen
		# Timer completes, order placed phone animation plays
			# player uses cell phone control key to open cell phone, cell phone slide up anim. plays
			# phone displays place to pickup order from, order text, time to complete dispatch, delivery fee & tip get.
			# player can accept or deny dispatch
				# if player declines, order timer restarts.
				# if player accepts:
					# available text hide
					# dispatched text show
					# timer label and timer show
					# phone displays On Dispatch - go to "Place Name"
					# order timer sleeps
					# 3D area teleports to place location
					# GPS arrow displays, pointing at Place to pick up
					# phone plays slide down anim for player, as they may want to get started right away
					# if player does not reach destination in time, order is cancelled, no money gained.
		# player on dispatch - get to place
			# drive into circle, wait for 1 second
			# teleport 3D area to destination location
			# GPS arrow changes to point at the area's next location
			# phone plays slide up anim for player
			# phone displays "Order picked up. Go to Destination"
		# player on dispatch - get to destination
			# drive into circle, wait for 1 second
			# teleport 3d area off map
			# clear GPS arrow
			# clear timer label and timer
			# phone plays slide up anim for player
			# phone displays "Dispatch completed - gained: $"
			# add money to total
			# if total money >= 500, then win screen with options to go back to start menu or exit are shown
			# if total money < 500 get order loop restarts


# Place name text, price float, order text
var orders = [
	["borger", 5.0, "Get 2 chicken sandwiches and 2 cheeseborgers."],
	["borger", 10.0, "Get a #9, Large, with a diet soda."],
	["borger", 20.0, "Get 2 large fries, 2 large nuggets, 4 fried pies"],
	["pizza", 10.0, "Get 1 Medium cheese pizza, with bones."],
	["pizza", 20.0, "Get 1 Large supreme pizza, boneless."],
	["pizza", 40.0, "Get 1 Large supreme, 1 Large cheese, and wings. All bones."],
	["italian", 20.0, "Get a personal lasagna."],
	["italian", 20.0, "Get a spaghetti plate with breadsticks."],
	["italian", 40.0, "Get the family sized lasagna pan with breadsticks"],
	["icecream", 20.0, "Get a 2 scoop chocolate cone."],
	["icecream", 40.0, "Get a frozen coffee drink."],
	["icecream", 40.0, "Get a pint of rocky road."],
	]

# pre-format text to show on the cellphone:
# show orders[0][0] (place name - Borgers),
# show orders[0][1] (price float - 5.0),
# show orders[0][2] (order text - "Get 2 chicken...")

