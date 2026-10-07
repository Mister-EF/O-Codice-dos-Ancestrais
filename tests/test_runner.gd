## TestRunner — Headless test runner scene executing logic tests and i18n validator.
class_name TestRunner
extends Node


func _ready() -> void:
	print("========================================")
	print("Codex of the Ancients — Test Runner")
	print("========================================")

	var i18n_validator: TestLocalizationValidator = TestLocalizationValidator.new()
	var i18n_ok: bool = i18n_validator.run_validation()

	var circuit_test: TestCircuitPuzzle = TestCircuitPuzzle.new()
	var circuit_ok: bool = circuit_test.run_all()

	if i18n_ok and circuit_ok:
		print("========================================")
		print("ALL TESTS PASSED SUCCESSFULLY!")
		print("========================================")
	else:
		push_error("SOME TESTS FAILED! Check log above.")
