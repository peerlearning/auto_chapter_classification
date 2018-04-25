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

					options = ""
					unless p.options[0].nil?
						p.options.each do |op|
							options = options + " " + op.text
						end
					end

					solution = ""
					unless p.solution.nil?
						solution = solution + p.solution					
					end

				subj, grade, curr, ch_no, top_no = top.code.split('-')

					row = Hash[
						"subject" => subj,
						"grade" => grade,
						"curriculum" => curr,
						"chapter" => c.name,
						"chapter_no" => ch_no,
						"topic" => top.name, 
						"topic_no" => top_no,
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
						"options" => Rails::Html::FullSanitizer.new.sanitize(options),
						"solution" => Rails::Html::FullSanitizer.new.sanitize(solution),
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