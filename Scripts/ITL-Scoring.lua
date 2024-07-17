ITL = {}

ITL.logConstant = math.log(1.0638215)
ITL.maxPoints = 9000
ITL.ITLPoints = function(percDP, points)
	local firstTerm = math.log(math.min(percDP,75)+1) / ITL.logConstant 
	local secondTerm = 31 ^ ( math.max(0,percDP-75) / 25 )
	local finalPerc = (firstTerm + secondTerm - 1) / 100
	return finalPerc * points
end

ITL.getChartPoints = function(chartName)
	local points = tonumber(string.sub(chartName,1,4))
	return (true and points) or 0
end