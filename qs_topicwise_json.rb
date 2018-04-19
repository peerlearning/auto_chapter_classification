require 'active_support/core_ext/object/try' 
require 'action_view'

results = Array.new

allowedTypes = ["ConcepTest", "Spot Test", "In Class Exercise", 
				"Homework", "Test", "Pre-Reading Exercise","Miscellaneous", 
				"In Class Test" , "Illustration", "Module Exercise", 
				"Module Homework", "Pre-Class Exercise"]

				
Syllabus.all.select{|s| s.curriculum.present?}.each do |s|
	s.chapters.each do |c|
		c.topics.each do |top|
			top.problems.where(type.in => allowedTypes).each do |p|
				if (p.options[1].present?)

					row = Hash[
						"topic_code" => top.code,
						"chapter" => c.name,
						"topic" => top.name, 
						# p.text.size,
						# p.solution.size,
						"difficulty" => p.difficulty_rating,
						#p.answer,						# Q can have multiple correct answers leading to text overflow
						# p.tests.first.code,
						"problem_code" => p.code,
						"problem_status" => p.review_status,
						"problem_mongo_id" => p.id.to_s,							# For generating Q links on CMS
						"option_a" => Rails::Html::FullSanitizer.new.sanitize(p.options[0].text),
						"option_b" => Rails::Html::FullSanitizer.new.sanitize(p.options[1].text),
						"option_c" => Rails::Html::FullSanitizer.new.sanitize(p.options[2].text),
						"option_d" => Rails::Html::FullSanitizer.new.sanitize(p.options[3].text),
						"question_text" => Rails::Html::FullSanitizer.new.sanitize(p.text)
						]
				
						results.push(row)	
						
				end
			end
		end
	end
end

puts results.to_json
f = open('qs_topicwise.json', 'w')
f.write(JSON.pretty_generate(results))
f.close()