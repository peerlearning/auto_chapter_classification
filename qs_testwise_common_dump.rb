require 'active_support/core_ext/object/try' 
require 'action_view'

file = File.open("testwise_common_dump.tsv", "w")
file.puts "Problem Code \t Right Ans \t Difficulty \t Chapter \t Chapter Code \t Test Code \t Q Text" 


test_list = [		

"JS-B-61-17", "X-B-01-16", "JS-B-62-17", "X-B-02-16", "X-B-03-16", "JS-B-63-17", "X-B-04-16", "X-B-05-16", "JS-C-61-17", "X-C-01-16", "X-C-02-16", "JS-C-62-17", "X-C-03-16", "JS-C-63-17", "JS-C-64-17", "X-C-04-16", "X-C-05-16", "JS-M-61-17", "X-M-01-16", "JS-M-62-17", "X-M-02-16", "X-M-03-16", "JS-M-63-17", "JS-M-64-17", "X-M-04-16", "JS-M-65-17", "X-M-05-16", "JS-M-66-17", "X-M-06-16", "JS-M-67-17", "X-M-07-16", "JS-M-68-17", "JS-M-69-17", "JS-M-70-17", "X-M-10-16", "JS-M-71-17", "X-M-11-16", "JS-M-72-17", "JS-M-73-17", "JS-M-74-17", "X-M-14-16", "X-M-15-16", "JS-M-75-17", "X-P-01-16", "JS-P-61-17", "X-P-02-16", "JS-P-63-17", "X-P-03-16", "JS-P-64-17", "X-P-04-16", "JS-P-65-17", "X-P-05-16", "X-M-27-17", "X-M-70-17", "JS-B-01-17", "JS-B-02-17", "JS-B-03-17", "JS-B-04-17", "JS-B-05-17", "JS-B-06-17", "JS-B-07-17", "JS-C-01-17", "JS-C-02-17", "JS-C-03-17", "JS-C-04-17", "JS-M-01-17", "JS-M-02-17", "JS-M-03-17", "JS-M-05-17", "JS-M-06-17", "JS-M-07-17", "JS-M-08-17", "JS-M-09-17", "JS-M-10-17", "JS-M-11-17", "JS-M-12-17", "JS-M-13-17", "JS-M-14-17", "JS-M-15-17", "JS-M-16-17", "JS-P-01-17", "JS-P-02-17", "JS-P-03-17", "JS-P-04-17", "JS-P-05-17", "JS-P-06-17", "JS-B-31-17", "JS-B-01-16", "JS-B-32-17", "JS-B-02-16", "JS-B-03-16", "JS-B-04-16", "JS-B-36-17", "JS-B-06-16", "JS-C-31-17", "JS-C-01-16", "JS-C-02-16", "JS-C-32-17", "JS-C-33-17", "JS-C-03-16", "JS-C-04-16", "JS-M-31-17", "JS-M-01-16", "JS-M-02-16", "JS-M-32-17", "JS-M-03-16", "JS-M-04-16", "JS-M-34-17", "JS-M-36-17", "JS-M-06-16", "JS-M-37-17", "JS-M-07-16", "JS-M-38-17", "JS-M-08-16", "JS-M-39-17", "JS-M-09-16", "JS-M-40-17", "JS-M-10-16", "JS-M-11-16", "JS-M-42-17", "JS-M-12-16", "JS-M-13-16", "JS-M-43-17", "JS-M-14-16", "JS-M-44-17", "JS-M-45-17", "JS-P-31-17", "JS-P-01-16", "JS-P-32-17", "JS-P-02-16", "JS-P-33-17", "JS-P-03-16", "JS-P-04-16", "JS-P-34-17", "JS-P-05-16", 

]										# Subjective test codes

test_list.each do |code|

	
		
		# list = Test.find_by(code: code).test_sets.where(name: "A").first.problem_ids # for Major Tests
		list = ChapterTest.find_by(code: code).test_sets.where(name: "A").first.problem_ids # for Chapter Tests
		
		    def convert_num_to_alpha(num)
		        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')[num.to_i-1]
		    end

		list.each do |p_id|
			p = Problem.find(p_id)	
		 
		 	row = [
		 		p_id,
		 		p.code,
		 		# p.solution.size,
				p.answer.map {|ans| convert_num_to_alpha(ans).downcase},
				p.difficulty_rating,
				p.topics.first.chapter.name,
				p.topics.first.chapter.code,
				# p.skill.name,
				# p.topics.first.chapter.syllabus.grade.name,
				code,
				#p.primary_subject, 
				# p.tests.first.name,
				# p.statistics.total_appearances, 
				# p.statistics.total_attempted, 
				# p.statistics.total_correct,
				Rails::Html::FullSanitizer.new.sanitize(p.options[0].text),
				Rails::Html::FullSanitizer.new.sanitize(p.options[1].text),
				Rails::Html::FullSanitizer.new.sanitize(p.options[2].text),
				Rails::Html::FullSanitizer.new.sanitize(p.options[3].text),
				Rails::Html::FullSanitizer.new.sanitize(p.text)
			]
							
			puts row.join("\t")
			file.puts row.join("\t")
			
		end
	
end

file.close
