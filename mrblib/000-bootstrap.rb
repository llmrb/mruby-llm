# frozen_string_literal: true

class Module
  def require_relative(*)
    true
  end

  def private_constant(*)
    self
  end

  def private_class_method(*)
    self
  end
end

module Kernel
  def require_relative(*)
    true
  end
end

module LLM
end
