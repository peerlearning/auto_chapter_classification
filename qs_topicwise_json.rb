require 'active_support/core_ext/object/try' 
require 'action_view'

results = Array.new
puts "Starting code...."
allowedTypes = ["Test", "ConcepTest", "Spot Test", "Homework", "Pre-Reading Exercise", "In Class Test" , "Module Exercise", 
				"Module Homework", "Pre-Class Exercise", "Pre Test", "In Class Exercise", "Homework", "Activity", 
				"Recall Test","Miscellaneous", "Illustration", "Module Exercise"
				]



Syllabus.all.select{|s| s.curriculum.present?}.each do |s|
	s.chapters.each do |c|
		c.topics.each do |top|
			top.problems.where(:type.in => allowedTypes).each do |p|
			
				if ( p.text != nil 
					# p.options[3].present?
					)

				document_text = p.text

				p.options.each do |op|
					document_text = document_text + " " + op.text
				end

				unless p.solution.nil?
					document_text = document_text + " " + p.solution					
				end

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
						"problem_mongo_id" => p.id.to_s,				# For generating Q links on CMS
						"problem_type" => p.type,
						# "option_a" => Rails::Html::FullSanitizer.new.sanitize(p.options[0].text),
						# "option_b" => Rails::Html::FullSanitizer.new.sanitize(p.options[1].text),
						# "option_c" => Rails::Html::FullSanitizer.new.sanitize(p.options[2].text),
						# "option_d" => Rails::Html::FullSanitizer.new.sanitize(p.options[3].text),
						# "question_text" => Rails::Html::FullSanitizer.new.sanitize(p.solution),
						"question_text" => Rails::Html::FullSanitizer.new.sanitize(document_text)
						 ]
				
						results.push(row)	
				else
					puts p.id.to_s
						
				end
			end
		end
	end
end

puts results.to_json
f = open('qs_topicwise.json', 'w')
f.write(JSON.pretty_generate(results))
f.close()