require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')

describe 'quizzes question creation' do

  include_examples 'quizzes selenium tests'

  before(:each) do
    course_with_teacher_logged_in
    @last_quiz = start_quiz_question
  end

  context 'when the \'+ New Question\' button is clicked' do

    it 'should open a new question form', priority: "1", test_id: 140627 do
      # setup is accomplished in before(:each)
      expect(fj('.question_form:visible')).to be_displayed
    end
  end

  # Multiple Choice Question
  it 'should create a quiz with a multiple choice question', priority: "1", test_id: 201942 do
    quiz = @last_quiz
    create_multiple_choice_question
    quiz.reload
    question_data = quiz.quiz_questions[0].question_data
    expect(f("#question_#{quiz.quiz_questions[0].id}")).to be_displayed

    expect(question_data[:answers].length).to eq 4
    expect(question_data[:answers][0][:text]).to eq 'Correct Answer'
    expect(question_data[:answers][0][:weight]).to eq 100
    expect(question_data[:answers][0][:comments_html]).to eq '<p>Good job!</p>'
    expect(question_data[:answers][1][:text]).to eq 'Wrong Answer #1'
    expect(question_data[:answers][1][:weight]).to eq 0
    expect(question_data[:answers][1][:comments_html]).to eq '<p>Bad job :(</p>'
    expect(question_data[:answers][2][:text]).to eq 'Second Wrong Answer'
    expect(question_data[:answers][2][:weight]).to eq 0
    expect(question_data[:answers][3][:text]).to eq 'Wrongest Answer'
    expect(question_data[:answers][3][:weight]).to eq 0
    expect(question_data[:points_possible]).to eq 1
    expect(question_data[:question_type]).to eq 'multiple_choice_question'
    expect(question_data[:correct_comments_html]).to eq '<p>Good job on the question!</p>'
    expect(question_data[:incorrect_comments_html]).to eq '<p>You know what they say - study long study wrong.</p>'
    expect(question_data[:neutral_comments_html]).to eq '<p>Pass or fail you are a winner!</p>'
  end

  # True/False Question
  it 'should create a quiz question with a true false question', priority: "1", test_id: 140628 do
    quiz = @last_quiz
    create_true_false_question
    quiz.reload
    keep_trying_until { expect(f("#question_#{quiz.quiz_questions[0].id}")).to be_displayed }

    quiz.reload
    question_data = quiz.quiz_questions[0].question_data
    expect(question_data[:answers][1][:comments_html]).to eq '<p>Good job!</p>'
  end

  # Fill-in-the-blank Question
  it 'should create a quiz question with a fill in the blank question', priority: "1", test_id: 197492 do
    quiz = @last_quiz
    create_fill_in_the_blank_question
    quiz.reload
    expect(f("#question_#{quiz.quiz_questions[0].id}")).to be_displayed
  end

  # Multiple Blanks Question
  it 'should create a quiz question with a fill in multiple blanks question', priority: "1", test_id: 197508 do
    quiz = @last_quiz

    question = fj('.question_form:visible')
    click_option('.question_form:visible .question_type', 'Fill In Multiple Blanks')

    replace_content(question.find_element(:css, "input[name='question_points']"), '4')

    type_in_tiny '.question:visible textarea.question_content', 'Roses are [color1], violets are [color2]'

    #check answer select
    select_box = question.find_element(:css, '.blank_id_select')
    select_box.click
    options = select_box.find_elements(:css, 'option')
    expect(options[0].text).to eq 'color1'
    expect(options[1].text).to eq 'color2'

    #input answers for both blank input
    answers = question.find_elements(:css, '.form_answers > .answer')

    replace_content(answers[0].find_element(:css, '.short_answer input'), 'red')
    replace_content(answers[1].find_element(:css, '.short_answer input'), 'green')
    options[1].click
    wait_for_ajaximations
    answers = question.find_elements(:css, '.form_answers > .answer')

    replace_content(answers[2].find_element(:css, '.short_answer input'), 'blue')
    replace_content(answers[3].find_element(:css, '.short_answer input'), 'purple')

    submit_form(question)
    wait_for_ajax_requests

    f('#show_question_details').click
    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    expect(finished_question).to be_displayed

    #check select box on finished question
    select_box = finished_question.find_element(:css, '.blank_id_select')
    select_box.click
    options = select_box.find_elements(:css, 'option')
    expect(options[0].text).to eq 'color1'
    expect(options[1].text).to eq 'color2'
  end

  # Multiple Answers Question
  it 'should create a quiz question with a multiple answers question', priority: "1", test_id: 140629 do
    quiz = @last_quiz

    question = fj('.question_form:visible')
    click_option('.question_form:visible .question_type', 'Multiple Answers')

    type_in_tiny '.question:visible textarea.question_content', 'This is a multiple answer question.'

    answers = question.find_elements(:css, '.form_answers > .answer')

    replace_content(answers[0].find_element(:css, '.select_answer input'), 'first answer')
    replace_content(answers[2].find_element(:css, '.select_answer input'), 'second answer')
    answers[2].find_element(:css, '.select_answer_link').click

    submit_form(question)
    wait_for_ajax_requests

    f('#show_question_details').click
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    expect(finished_question).to be_displayed
    expect(finished_question.find_elements(:css, '.answer.correct_answer').length).to eq 2
  end

  # Multiple Dropdown Question
  it 'should create a quiz question with a multiple dropdown question', priority: "1", test_id: 197510 do
    quiz = @last_quiz

    question = fj('.question_form:visible')
    click_option('.question_form:visible .question_type', 'Multiple Dropdowns')

    type_in_tiny '.question:visible textarea.question_content', 'Roses are [color1], violets are [color2]'

    #check answer select
    select_box = question.find_element(:css, '.blank_id_select')
    select_box.click
    options = select_box.find_elements(:css, 'option')
    expect(options[0].text).to eq 'color1'
    expect(options[1].text).to eq 'color2'

    #input answers for both blank input
    answers = question.find_elements(:css, '.form_answers > .answer')
    answers[0].find_element(:css, '.select_answer_link').click

    replace_content(answers[0].find_element(:css, '.select_answer input'), 'red')
    replace_content(answers[1].find_element(:css, '.select_answer input'), 'green')
    options[1].click
    wait_for_ajaximations
    answers = question.find_elements(:css, '.form_answers > .answer')

    answers[2].find_element(:css, '.select_answer_link').click
    replace_content(answers[2].find_element(:css, '.select_answer input'), 'blue')
    replace_content(answers[3].find_element(:css, '.select_answer input'), 'purple')

    submit_form(question)
    wait_for_ajax_requests

    driver.execute_script("$('#show_question_details').click();")
    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    expect(finished_question).to be_displayed

    #check select box on finished question
    select_box = finished_question.find_element(:css, '.blank_id_select')
    select_box.click
    options = select_box.find_elements(:css, 'option')
    expect(options[0].text).to eq 'color1'
    expect(options[1].text).to eq 'color2'
  end

  context 'when creating a matching question' do

    # Matching Question
    it 'should be able to create a basic matching question', priority: "1", test_id: 201943 do
      quiz = @last_quiz

      question = fj('.question_form:visible')
      click_option('.question_form:visible .question_type', 'Matching')

      type_in_tiny '.question:visible textarea.question_content', 'This is a matching question.'

      answers = question.find_elements(:css, '.form_answers > .answer')

      answers.each_with_index do |answer, i|
        answer.find_element(:name, 'answer_match_left').send_keys("#{i} left side")
        answer.find_element(:name, 'answer_match_right').send_keys("#{i} right side")
      end

      submit_form(question)
      wait_for_ajax_requests

      f('#show_question_details').click
      finished_question = f("#question_#{quiz.quiz_questions[0].id}")

      finished_question.find_elements(:css, '.answer_match').each_with_index do |filled_answer, i|
        expect(filled_answer.find_element(:css, '.answer_match_left')).to include_text("#{i} left side")
        expect(filled_answer.find_element(:css, '.answer_match_right')).to include_text("#{i} right side")
      end
    end

    it 'should be able to create a matching question with distractors', priority: "1", test_id: 220014 do
      quiz = @last_quiz

      question = fj('.question_form:visible')
      click_option('.question_form:visible .question_type', 'Matching')

      type_in_tiny '.question:visible textarea.question_content', 'This is a matching question.'

      answers = question.find_elements(:css, '.form_answers > .answer')

      answers.each_with_index do |answer, i|
        answer.find_element(:name, 'answer_match_left').send_keys("#{i} left side")
        answer.find_element(:name, 'answer_match_right').send_keys("#{i} right side")
      end

      # add a distractor
      distractor_content = 'first_distractor'
      question.find_element(:name, 'matching_answer_incorrect_matches').send_keys(distractor_content)

      submit_form(question)
      wait_for_ajax_requests

      f('#show_question_details').click
      finished_question = f("#question_#{quiz.quiz_questions[0].id}")

      expect(finished_question).to include_text(distractor_content)
    end

  end

  # Numerical Answer
  it 'should be able to create a basic numerical answer question', priority: "1", test_id: 201944 do
    quiz = @last_quiz

    click_option('.question_form:visible .question_type', 'Numerical Answer')
    type_in_tiny '.question:visible textarea.question_content', 'This is a numerical question.'

    quiz_form = f('.question_form')
    answers = quiz_form.find_elements(:css, '.form_answers > .answer')
    replace_content(answers[0].find_element(:name, 'answer_exact'), 5)
    replace_content(answers[0].find_element(:name, 'answer_error_margin'), 2)
    click_option('select.numerical_answer_type:eq(1)', 'Answer in the Range:')
    replace_content(answers[1].find_element(:name, 'answer_range_start'), 5)
    replace_content(answers[1].find_element(:name, 'answer_range_end'), 10)
    submit_form(quiz_form)
    wait_for_ajaximations

    f('#show_question_details').click
    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    expect(finished_question).to be_displayed

  end

  # Formula Question
  it 'should be able to create a basic formula question', priority: "1", test_id: 201945 do
    quiz = @last_quiz

    question = fj('.question_form:visible')
    click_option('.question_form:visible .question_type', 'Formula Question')

    type_in_tiny '.question_form:visible textarea.question_content', 'If [x] + [y] is a whole number, then this is a formula question.'

    fj('button.recompute_variables').click
    fj('.supercalc:visible').send_keys('x + y')
    fj('button.save_formula_button').click
    # normally it's capped at 200 (to keep the yaml from getting crazy big)...
    # since selenium tests take forever, let's make the limit much lower
    driver.execute_script('ENV.quiz_max_combination_count = 10')
    fj('.combination_count:visible').send_keys('20') # over the limit
    button = fj('button.compute_combinations:visible')
    button.click
    expect(fj('.combination_count:visible')).to have_attribute(:value, '10')
    keep_trying_until {
      button.text == 'Generate'
    }
    expect(ffj('table.combinations:visible tr').size).to eq 11 # plus header row
    submit_form(question)
    wait_for_ajax_requests

    quiz.reload
    expect(f("#question_#{quiz.quiz_questions[0].id}")).to be_displayed
  end

  # Essay Question
  it 'should be able to create a basic essay question', priority: "1", test_id: 201946 do
    quiz = @last_quiz

    question = fj('.question_form:visible')
    click_option('.question_form:visible .question_type', 'Essay Question')

    type_in_tiny '.question:visible textarea.question_content', 'This is an essay question.'
    submit_form(question)
    wait_for_ajax_requests

    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    expect(finished_question).not_to be_nil
    expect(finished_question.find_element(:css, '.text')).to include_text('This is an essay question.')
  end

  # File Upload Question
  it 'should be able to create a basic file upload question', priority: "1", test_id: 201947 do
    quiz = @last_quiz

    create_file_upload_question

    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    expect(finished_question).not_to be_nil
    expect(finished_question.find_element(:css, '.text')).to include_text('This is a file upload question.')
  end

  # Text Answer Question
  it 'should be able to create a basic text answer question', priority: "1", test_id: 201948 do
    quiz = @last_quiz

    question = fj('.question_form:visible')
    click_option('.question_form:visible .question_type', 'Text (no question)')

    type_in_tiny '.question_form:visible textarea.question_content', 'This is a text question.'
    submit_form(question)
    wait_for_ajax_requests

    quiz.reload
    finished_question = f("#question_#{quiz.quiz_questions[0].id}")
    expect(finished_question).not_to be_nil
    expect(finished_question.find_element(:css, '.text')).to include_text('This is a text question.')
  end

  # Negative Question Points
  it 'should not allow negative question points', priority: "2", test_id: 201953 do
    quiz = @last_quiz
    question = fj('.question_form:visible')
    click_option('.question_form:visible .question_type', 'essay_question', :value)

    replace_content(question.find_element(:css, "input[name='question_points']"), '-4')
    submit_form(question)

    wait_for_ajaximations
    expect(question).to be_displayed
    assert_error_box(".question_form:visible input[name='question_points']")
  end

  context 'when a quiz has more than 25 questions', priority: "1", test_id: 140578 do

    def quiz_questions_creation
      @q = @course.quizzes.create!(title: 'new quiz')
      26.times do
        @q.quiz_questions.create!(question_data: {name: 'Quiz Questions', question_type: 'essay_question', question_text: 'qq_1', answers: [], points_possible: 1})
      end
      @q.generate_quiz_data
      @q.workflow_state = 'available'
      @q.save
      @q.reload
    end

    before(:each) do
      course_with_teacher_logged_in
      quiz_questions_creation
    end

    it 'should edit quiz questions' do
      get "/courses/#{@course.id}/quizzes/#{@q.id}/edit"
      click_questions_tab
      driver.execute_script("$('.display_question').first().addClass('hover').addClass('active')")
      fj('.edit_teaser_link').click
      wait_for_ajaximations
      type_in_tiny '.question:visible textarea.question_content', 'This is an essay question.'
      submit_form(fj('.question_form:visible'))
      wait_for_ajax_requests
    end
  end

  context 'when editing a quiz question group', priority: "2" do
    it 'should add questions from a question bank', priority: "1", test_id: 140671 do
      quiz_with_new_questions
      click_questions_tab
      f('.find_question_link').click
      wait_for_ajaximations
      f('.select_all_link').click

      click_option('.quiz_group_select', 'new', :value)
      f('#found_question_group_name').send_keys('group1')
      f('#found_question_group_pick').send_keys(2)
      f('#found_question_group_points').send_keys(2)
      submit_dialog('#add_question_group_dialog', '.submit_button')
      wait_for_ajax_requests
      submit_dialog('#find_question_dialog', '.submit_button')
      wait_for_ajax_requests
      expect(f('.quiz_group_form')).to be_displayed
    end
  end
end
