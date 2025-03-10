extends Node



@onready var divorces_data = preload("res://divorces_2000-2015_translated.csv").records
@onready var astro_data = preload("res://Comp_matrix.csv").records
var curated_divorce_data = []


@onready var country_rate: SpinBox = $Control/VBoxContainer/Control/SpinBox
@onready var result: Label = $Control/VBoxContainer/HBoxContainer/Result/VBox/ResultValue

var man_married: bool = false
var woman_married: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print("divorces_data: ", divorces_data)
	print("astro_data: ", astro_data)
	clear_data()
	pass


func clear_data() -> void:
	print(divorces_data.size())
	for data_dict in divorces_data:
		if not(data_dict["DOB_partner_man"] == "" or data_dict["DOB_partner_woman"] == "" or data_dict["Monthly_income_partner_man_peso"] == "" or data_dict["Monthly_income_partner_woman_peso"] == ""or data_dict["Date_of_marriage"] == ""or data_dict["Marriage_duration"] == "" or data_dict["Num_Children"] == ""):
			curated_divorce_data.append(data_dict)
			pass
		pass
	print(curated_divorce_data.size())
	#print(curated_divorce_data)
	pass


func compute_rate() -> void:
	var value = 0
	var coeff = 0
	var computations = []
	var zodiac_comp = match_birth_dates()
	print("zodiac_comp: ", zodiac_comp)
	if not zodiac_comp.is_empty():
		computations.append(zodiac_comp)
	var salaries = match_salaries()
	print("salaries: ", salaries)
	if not salaries.is_empty():
		computations.append(salaries)
	var ages = match_marriage_age()
	print("ages: ", ages)
	if not ages.is_empty():
		computations.append(ages)
	var duration = match_marriage_duration()
	print("duration: ", duration)
	if not duration.is_empty():
		computations.append(duration)
	var children = match_marriage_children()
	print("children: ", children)
	if not children.is_empty():
		computations.append(children)
	for values in computations:
		value += values[0]*values[1]
		coeff += values[1]
		pass
	print("computations: ", computations)
	print("coeff: ", coeff)
	value = value / coeff if coeff != 0 else 1
	result.set_text(str((value * country_rate.value/100)*100) + " %")
	pass


@onready var salary_man = $Control/VBoxContainer/HBoxContainer/Person1/DataVBox/Income/Input
@onready var salary_woman = $Control/VBoxContainer/HBoxContainer/Person2/DataVBox/Income/Input
@onready var salary_inf = $Control/VBoxContainer/HBoxContainer/Person1/DataVBox/Income/HSlider

func match_salaries() -> Array:
	var compatibility: Array = []
	var man_money = salary_man.value
	var woman_money = salary_woman.value
	var count = 0.0
	for divorce in curated_divorce_data:
		if int(divorce["Monthly_income_partner_man_peso"]) > man_money and int(divorce["Monthly_income_partner_woman_peso"]) > woman_money:
			count += 1
		pass
	print("count: ", count)
	compatibility = [count / curated_divorce_data.size(), salary_inf.value / 100]
	return compatibility


@onready var dob_man = $Control/VBoxContainer/HBoxContainer/Person1/DataVBox/BirthDate/Input
@onready var dob_woman = $Control/VBoxContainer/HBoxContainer/Person2/DataVBox/BirthDate/Input
@onready var dob_inf = $Control/VBoxContainer/HBoxContainer/Person1/DataVBox/BirthDate/HSlider

func match_birth_dates() -> Array:
	var compatibility = []
	if dob_man.text.length() != 10 or dob_woman.text.length() != 10:
		print("missing birth date")
		return compatibility
	var date_man_full = dob_man.text
	var date_woman_full = dob_woman.text
	var zodiac_man = zodiac_sign(int(date_man_full.split("/")[0]), int(date_man_full.split("/")[1]))
	var zodiac_woman = zodiac_sign(int(date_woman_full.split("/")[0]), int(date_woman_full.split("/")[1]))
	var zodiac_combination = zodiac_man + zodiac_woman
	print("zodiac_combination: ", zodiac_combination)
	for combination in astro_data:
		if combination["Zodiac_combination"] == zodiac_combination:
			compatibility = [1 - combination["Compatibility_rate"], dob_inf.value / 100]
			pass
		pass
	return compatibility


func zodiac_sign(day: int, month: int):
	if month == 12: 
		return 'Sagittarius' if (day < 22) else 'Capricorn'
	elif month == 1: 
		return 'Capricorn' if (day < 20) else 'Aquarius'
	elif month == 2: 
		return 'Aquarius' if (day < 19) else 'Pisces'
	elif month == 3: 
		return 'Pisces' if (day < 21) else 'Aries'
	elif month == 4: 
		return 'Aries' if (day < 20) else 'Taurus'
	elif month == 5: 
		return 'Taurus' if (day < 21) else 'Gemini'
	elif month == 6: 
		return 'Gemini' if (day < 21) else 'Cancer'
	elif month == 7: 
		return 'Cancer' if (day < 23) else 'Leo'
	elif month == 8: 
		return 'Leo' if (day < 23) else 'Virgo'
	elif month == 9: 
		return 'Virgo' if (day < 23) else 'Libra'
	elif month == 10: 
		return 'Libra' if (day < 23) else 'Scorpio'
	elif month == 11: 
		return 'Scorpio' if (day < 22) else 'Sagittarius'


func _on_compute_button_pressed() -> void:
	compute_rate()
	pass

@onready var man_age_at_marriage = $Control/VBoxContainer/HBoxContainer/Person1/DataVBox/AgeAtMarriage
@onready var man_marriage_duration = $Control/VBoxContainer/HBoxContainer/Person1/DataVBox/MarriageDuration
@onready var man_children_in_mariage = $Control/VBoxContainer/HBoxContainer/Person1/DataVBox/ChildrenInMarriage

func _on_man_married_yet_toggled(toggled_on: bool) -> void:
	man_married = toggled_on
	man_age_at_marriage.visible = toggled_on
	man_marriage_duration.visible = toggled_on
	man_children_in_mariage.visible = toggled_on
	pass

@onready var woman_age_at_marriage = $Control/VBoxContainer/HBoxContainer/Person2/DataVBox/AgeAtMarriage
#@onready var woman_marriage_duration = $Control/VBoxContainer/HBoxContainer/Person2/DataVBox/MarriageDuration
#@onready var woman_children_in_mariage = $Control/VBoxContainer/HBoxContainer/Person2/DataVBox/ChildrenInMarriage

func _on_woman_married_yet_toggled(toggled_on: bool) -> void:
	woman_married = toggled_on
	woman_age_at_marriage.visible = toggled_on
	#woman_marriage_duration.visible = toggled_on
	#woman_children_in_mariage.visible = toggled_on
	pass


@onready var age_man = $Control/VBoxContainer/HBoxContainer/Person1/DataVBox/AgeAtMarriage/Input
@onready var age_woman = $Control/VBoxContainer/HBoxContainer/Person2/DataVBox/AgeAtMarriage/Input
@onready var age_inf = $Control/VBoxContainer/HBoxContainer/Person1/DataVBox/AgeAtMarriage/HSlider

func match_marriage_age() -> Array:
	var compatibility: Array = []
	if !man_married or !woman_married:
		return compatibility
	var man_age = age_man.value
	var woman_age = age_woman.value
	var count = 0.0
	for divorce in curated_divorce_data:
		if int(divorce["Age_partner_man"]) - int(divorce["Marriage_duration"]) < man_age and int(divorce["Age_partner_woman"]) - int(divorce["Marriage_duration"]) < woman_age:
			count += 1
		pass
	print("count: ", count)
	compatibility = [count / curated_divorce_data.size(), age_inf.value / 100]
	return compatibility


@onready var duration_marriage = $Control/VBoxContainer/HBoxContainer/Person1/DataVBox/MarriageDuration/Input
@onready var duration_inf = $Control/VBoxContainer/HBoxContainer/Person1/DataVBox/MarriageDuration/HSlider

func match_marriage_duration() -> Array:
	var compatibility: Array = []
	if !man_married or !woman_married:
		return compatibility
	var duration = duration_marriage.value
	var count = 0.0
	for divorce in curated_divorce_data:
		if int(divorce["Marriage_duration"]) > duration:
			count += 1
		pass
	print("count: ", count)
	compatibility = [count / curated_divorce_data.size(), duration_inf.value / 100]
	return compatibility


@onready var children_marriage = $Control/VBoxContainer/HBoxContainer/Person1/DataVBox/ChildrenInMarriage/Input
@onready var children_inf = $Control/VBoxContainer/HBoxContainer/Person1/DataVBox/ChildrenInMarriage/HSlider

func match_marriage_children() -> Array:
	var compatibility: Array = []
	if !man_married or !woman_married:
		return compatibility
	var children = children_marriage.value
	var count = 0.0
	for divorce in curated_divorce_data:
		if int(divorce["Num_Children"]) > children:
			count += 1
		pass
	print("count children: ", count)
	compatibility = [count / curated_divorce_data.size(), children_inf.value / 100]
	return compatibility
