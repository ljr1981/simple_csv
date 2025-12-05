note
	description: "Base class for test sets providing common assertions"
	author: "Larry Rix"

deferred class
	TEST_SET_BASE

inherit
	EQA_TEST_SET

feature -- Assertions

	assert_strings_equal (a_tag: STRING; a_expected, a_actual: STRING)
			-- Assert two strings are equal.
		do
			assert (a_tag, a_expected.same_string (a_actual))
		end

	assert_integers_equal (a_tag: STRING; a_expected, a_actual: INTEGER)
			-- Assert two integers are equal.
		do
			assert (a_tag, a_expected = a_actual)
		end

end
