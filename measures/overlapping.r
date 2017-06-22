# R Code
# Overlapping Measures
# L. P. F. Garcia A. C. Lorena and M. de Souto 2016
# The set of Overlapping Measures

# Feature overlapping measures from:
#@article{ho2002complexity,
#  title={Complexity measures of supervised classification problems},
#  author={Ho, Tin Kam and Basu, Mitra},
#  journal={IEEE transactions on pattern analysis and machine intelligence},
#  volume={24},
#  number={3},
#  pages={289--300},
#  year={2002},
#  publisher={IEEE}
#}

# and

#@article{sotoca2005review,
#  title={A review of data complexity measures and their applicability to pattern classification problems},
#  author={Sotoca, JM and Sanchez, JS and Mollineda, RA},
#  journal={Actas del III Taller Nacional de Mineria de Datos y Aprendizaje. TAMIDA},
#  pages={77--83},
#  year={2005}
#}

# and

#@article{orriols2010documentation,
#  title={Documentation for the data complexity library in C++},
#  author={Orriols-Puig, Albert and Macia, Nuria and Ho, Tin Kam},
#  journal={Universitat Ramon Llull, La Salle},
#  volume={196},
#  year={2010}
#}

# Taking all examples with class = j
branch <- function(data, j) {
	data[data$class == j, -ncol(data), drop = FALSE]
}

# Means from the same class (numerator from measure F1 from Mollineda)
num <- function(data, j) {

	tmp = branch(data, j)
	aux = nrow(tmp) * (colMeans(tmp) - 
		colMeans(data[,-ncol(data)]))^2
	return(aux)
}

# Standard deviations (denominator from measure F1 from Mollineda)
den <- function(data, j) {

	tmp = branch(data, j)
	aux = rowSums((t(tmp) - colMeans(tmp))^2)
	return(aux)
}

# Fisher’s discriminant ratio (F1)
f1 <- function(data) {

	aux = mapply(function(j) {
		num(data, j)/den(data, j)
	}, j=levels(data$class))

	aux[aux == Inf] = NA
	aux = rowSums(aux, na.rm=TRUE)
	return(max(aux)) # taking the maximum between all features
}

# Auxiliary function for F2
regionOver <- function(data) {

	l = levels(data$class)
	a = branch(data, l[1])
	b = branch(data, l[2])

	maxmax = rbind(colMax(a), colMax(b))
	minmin = rbind(colMin(a), colMin(b))

	over = colMax(rbind(colMin(maxmax) - colMax(minmin), 0))
	rang = colMax(maxmax) - colMin(minmin)

	aux = prod(over/rang, na.rm = TRUE)
	return(aux)
}

# Volume of overlap region (F2)
f2 <- function(data) {

	data = ovo(data); # multiclass problems have to be decomposed previously
	aux = unlist(lapply(data, regionOver))
	return(mean(aux)) # sum is not comparable 
	# ??? take the maximum???
}

# Auxiliary function for F3
# Examples that are not in overlapping region
nonOverlap <- function(data) {

	l = levels(data$class)
	a = branch(data, l[1])
	b = branch(data, l[2])

	minmax = colMin(rbind(colMax(a), colMax(b)))
	maxmin = colMax(rbind(colMin(a), colMin(b)))

	aux = do.call("cbind",
		lapply(1:(ncol(data)-1), 
			function(i) {
				data[,i] < maxmin[i] | data[,i] > minmax[i]
		})
	)

	aux = data.frame(aux)
	rownames(aux) = rownames(data)
	return(aux)
}

# Maximum (individual) feature efficiency (F3)
f3 <- function(data) {

	data = ovo(data); # multiclass problems have to be decomposed previously
	aux = mapply(function(d) {
		colSums(nonOverlap(d))/nrow(d)
	}, d=data)

	aux = mean(colMax(aux)) # ??? take the average or maximum?
	return(aux)
}

# Auxiliary function for F4
# Removes points in overlapping regions
removing <- function(data) {

	repeat {
		tmp = nonOverlap(data)
		col = which.max(colSums(tmp))
		aux = rownames(tmp[tmp[,col] != TRUE, , drop = FALSE])
		data = data[aux,- col, drop = FALSE]
		if(nrow(data) == 0 | ncol(data) == 1 |
			length(unique(data$class)) == 1)
			break
	}

	return(data)
}

# Collective Feature Efficiency (F4)
f4 <- function(data) {

	data = ovo(data); # multiclass problems have to be decomposed previously
	aux = mapply(function(d) {
		n = removing(d) # removes points in overlapping regions
		(nrow(d) - nrow(n))/nrow(d)
	}, d=data)

	aux = mean(aux) # or max???
	return(aux)
}

# Applying all measures from this category
fisher <- function(data) {

	data = binarize(data)

	aux = lapply(OVERLAPPING, 
		function(i) {
			do.call(i, list(data))
	})

	aux = unlist(aux)
	names(aux) = OVERLAPPING
	return(aux)
}

