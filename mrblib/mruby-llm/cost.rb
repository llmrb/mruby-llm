# frozen_string_literal: true

##
# The {LLM::Cost LLM::Cost} class represents an approximate
# cost breakdown for a provider request. It stores the input
# and output costs separately and can return the total.
#
# @attr [Float] input_costs
#   Returns the input cost
# @attr [Float] output_costs
#   Returns the output cost
class LLM::Cost < Struct.new(:input_costs, :output_costs)
  ##
  # @return [Float]
  #  Returns the total cost
  def total
    input_costs + output_costs
  end

  ##
  # @return [String]
  #  Returns the total cost in a human friendly format
  def to_s
    format("%.12f", total).sub(/\.?0+$/, "")
  end
end
