require File.expand_path('../config', __FILE__)

desc "あるチームの投稿を他のチームにそのままコピーする"
task :copy_posts_to_other_team do
  from_team = EsaBatch::Team.find_by_name(ENV.fetch('FROM_TEAM'))
  to_team = EsaBatch::Team.find_by_name(ENV.fetch('TO_TEAM'))
  q = ENV.fetch('QUERY', '')

  EsaBatch::Team.current_team = from_team
  posts = EsaBatch::Post.search_all(q: q)

  EsaBatch::Team.current_team = to_team
  posts.each do |post|
    post.push
  end
end
