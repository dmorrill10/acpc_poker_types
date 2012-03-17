require 'fileutils'

module Tasks
   def tag_gem_version(version)
      puts "Tagging #{version}..."
      system "git tag -a #{version} -m 'Tagging #{version}'"
      puts "Pushing #{version} to git..."
      system "git push --tags"
   end
end