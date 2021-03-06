class SubmissionPointsPossibleFixData < ActiveRecord::Migration
  tag :predeploy

  def self.up
    case connection.adapter_name
      when 'MySQL', 'Mysql2'
        update <<-SQL
          UPDATE #{Quizzes::QuizSubmission.quoted_table_name}, #{Quizzes::Quiz.quoted_table_name}
          SET quiz_points_possible = points_possible
          WHERE quiz_id = quizzes.id AND quiz_points_possible <> points_possible AND (points_possible < 2147483647 AND quiz_points_possible = CAST(points_possible AS SIGNED) OR points_possible >= 2147483647 AND quiz_points_possible = 2147483647)
        SQL
      when 'PostgreSQL'
        update <<-SQL
          UPDATE #{Quizzes::QuizSubmission.quoted_table_name}
          SET quiz_points_possible = points_possible
          FROM #{Quizzes::Quiz.quoted_table_name}
          WHERE quiz_id = quizzes.id AND quiz_points_possible <> points_possible AND (points_possible < 2147483647 AND quiz_points_possible = CAST(points_possible AS INTEGER) OR points_possible >= 2147483647 AND quiz_points_possible = 2147483647)
        SQL
      # no fix needed for sqlite
    end
  end

  def self.down
  end
end
