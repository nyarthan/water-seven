#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

require "pathname"
require "uri"
require "yaml"

NAME = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
LINK = /!?\[[^\]]*\]\(([^)]+)\)/

def fail!(message)
  raise message
end

def frontmatter(path)
  text = path.read(encoding: Encoding::UTF_8)
  match = text.match(/\A---\n(.*?)\n---\n/m)
  fail!("#{path}: missing valid frontmatter delimiters") unless match

  fields = YAML.safe_load(match[1], permitted_classes: [], permitted_symbols: [], aliases: false)
  fail!("#{path}: frontmatter must be a mapping") unless fields.is_a?(Hash)

  fields
rescue Psych::SyntaxError => error
  fail!("#{path}: invalid YAML frontmatter: #{error.message}")
end

def validate_links!(skill_dir)
  skill_dir.glob("**/*.md").each do |document|
    document.read(encoding: Encoding::UTF_8).scan(LINK).flatten.each do |raw_target|
      target = raw_target.strip
      target = target[1...-1] if target.start_with?("<") && target.end_with?(">")
      target = target.split(/\s+/, 2).first
      next if target.start_with?("#", "http://", "https://", "mailto:")

      path_part = URI::DEFAULT_PARSER.unescape(target.split("#", 2).first)
      next if path_part.empty?

      resolved = document.dirname.join(path_part)
      fail!("#{document}: broken relative link #{raw_target.inspect}") unless resolved.exist?
    end
  end
end

abort "usage: check-skills.rb <skills-directory>" unless ARGV.length == 1

begin
  root = Pathname(ARGV.fetch(0))
  fail!("#{root}: skill root does not exist") unless root.directory?

  nested = root.glob("**/SKILL.md").reject { |path| path.dirname.dirname == root }
  fail!("nested discoverable skills are not allowed: #{nested.join(", ")}") unless nested.empty?

  skill_dirs = root.children.select(&:directory?).sort
  fail!("#{root}: no skills found") if skill_dirs.empty?

  names = {}
  skill_dirs.each do |skill_dir|
    skill_file = skill_dir.join("SKILL.md")
    fail!("#{skill_dir}: missing SKILL.md") unless skill_file.file?

    fields = frontmatter(skill_file)
    name = fields.fetch("name", "")
    description = fields.fetch("description", "")

    fail!("#{skill_file}: invalid skill name #{name.inspect}") unless name.is_a?(String) && NAME.match?(name)
    fail!("#{skill_file}: name must match directory #{skill_dir.basename}") unless name == skill_dir.basename.to_s
    fail!("duplicate skill name #{name.inspect}: #{names[name]} and #{skill_file}") if names.key?(name)
    names[name] = skill_file

    fail!("#{skill_file}: description must not be empty") unless description.is_a?(String) && !description.empty?
    fail!("#{skill_file}: description exceeds 1024 characters") if description.length > 1024

    invocation = fields["disable-model-invocation"]
    unless invocation.nil? || invocation == true || invocation == false
      fail!("#{skill_file}: disable-model-invocation must be true or false")
    end

    if skill_dir.join("agents/openai.yaml").exist?
      fail!("#{skill_dir}: harness-specific agents/openai.yaml is not allowed")
    end

    validate_links!(skill_dir)
  end

  puts "validated #{names.length} skills"
rescue StandardError => error
  abort error.message
end
