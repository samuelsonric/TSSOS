using DynamicPolynomials
using TSSOS
using JuMP
using MosekTools
using MultivariatePolynomials

@polyvar x[1:2]
@polyvar y
f = ((x[1] - x[2])^2 - 2)^2

s = 1
t = 6
model = Model(optimizer_with_attributes(Mosek.Optimizer))
ω = add_poly!(model, y, 2s)[1]
q1 = add_poly!(model, x[1], 2t)[1]
q2 = add_poly!(model, x[1], 2t)[1]
add_psatz!(model, ω, [y], [1-y^2], [], s, TS=false)
add_psatz!(model, q1, [x[1]], [1-x[1]^2], [], t, TS=false)
add_psatz!(model, q2, [x[1]], [1-x[1]^2], [], t, TS=false)
p = ω*(((x[1] - y)^2 - 2)^2 - 1)
H1 = sum(MultivariatePolynomials.coefficient(p, y^i, [y])*(2/(i+1)) for i = 0:2:2s+4) + 1 + q1 - q2
H2 = subs(H1, x[1]=>x[2])
@variable(model, τ)
add_psatz!(model, [τ 0.5*(H1 + H2); 0.5*(H1 + H2) f], x, 1 .- x.^2, [], t, TS=false)
@objective(model, Min, 0.5*τ + coefficients(sum(MultivariatePolynomials.coefficient(q2 - 0.1*q1, x[1]^i, [x[1]])*(2/(i+1)) for i = 0:2:2t))[1])
optimize!(model)
optimum = objective_value(model)
@show optimum


@polyvar z[1:2]
model = Model(optimizer_with_attributes(Mosek.Optimizer))
ω = add_poly!(model, y, 2s)[1]
q1 = add_poly!(model, x[1], 2t)[1]
q2 = add_poly!(model, x[1], 2t)[1]
add_psatz!(model, ω, [y], [1-y^2], [], s, TS=false)
add_psatz!(model, q1, [x[1]], [1-x[1]^2], [], t, TS=false)
add_psatz!(model, q2, [x[1]], [1-x[1]^2], [], t, TS=false)
p = ω*(((x[1] - y)^2 - 2)^2 - 1)
H = sum(MultivariatePolynomials.coefficient(p, y^i, [y])*(2/(i+1)) for i = 0:2:2s+4) + 1 + q1 - q2
H1 = subs(H, x[1]=>z[1]+z[2])
H2 = subs(H, x[1]=>z[1]-z[2])
@variable(model, τ)
# add_psatz!(model, [τ 0.5*(H1 + H2); 0.5*(H1 + H2) f(x[1]=>z[1]+z[2], x[2]=>z[1]-z[2])], z, [1-(z[1]+z[2])^2, 1-(z[1]-z[2])^2], [], t, TS="block")
add_psatz!(model, [τ 0.5*(H1 + H2); 0.5*(H1 + H2) f(x[1]=>z[1]+z[2], x[2]=>z[1]-z[2])], z, [2-(z[1]+z[2])^2-(z[1]-z[2])^2, (1-(z[1]+z[2])^2)*(1-(z[1]-z[2])^2)], [], t, TS="block")
@objective(model, Min, 0.5*τ + coefficients(sum(MultivariatePolynomials.coefficient(q2 - 0.1*q1, x[1]^i, [x[1]])*(2/(i+1)) for i = 0:2:2t))[1])
optimize!(model)
optimum = objective_value(model)
@show optimum


model = Model(optimizer_with_attributes(Mosek.Optimizer))
sos1 = add_SOS!(model, y, s)
sos2 = add_SOS!(model, y, s-1)
sos3 = add_SOS!(model, x[1], t)
sos4 = add_SOS!(model, x[1], t-1)
sos5 = add_SOS!(model, x[1], t)
sos6 = add_SOS!(model, x[1], t-1)
p = (sos1 + sos2*(1 - y^2))*(((x[1] - y)^2 - 2)^2 + ((x[2] - y)^2 - 2)^2 - 2)
q1 = sos3 + sos4*(1 - x[1]^2)
q2 = subs(q1, x[1]=>x[2])
q3 = sos5 + sos6*(1 - x[1]^2)
q4 = subs(q3, x[1]=>x[2])
msos1 = add_SOSMatrix!(model, x, 2, t)[1]
msos2 = add_SOSMatrix!(model, x, 2, t-1)[1]
msos3 = add_SOSMatrix!(model, x, 2, t-1)[1]
@variable(model, τ)
@constraint(model, coefficients(0.5*sum(MultivariatePolynomials.coefficient(p, y^i, [y])*(2/(i+1)) for i = 0:2:2s+4) + 1 + 0.5*(q1 + q2 - q3 - q4) - msos1[1,2] - msos2[1,2]*(1-x[1]^2) - msos3[1,2]*(1-x[2]^2)) .== 0)
@constraint(model, coefficients(τ - msos1[1,1] - msos2[1,1]*(1-x[1]^2) - msos3[1,1]*(1-x[2]^2)) .== 0)
@constraint(model, coefficients(f - msos1[2,2] - msos2[2,2]*(1-x[1]^2) - msos3[2,2]*(1-x[2]^2)) .== 0)
@objective(model, Min, 0.5*τ + coefficients(sum(MultivariatePolynomials.coefficient(q3 - 0.1*q1, x[1]^i, [x[1]])*(2/(i+1)) for i = 0:2:2t))[1])
optimize!(model)
optimum = objective_value(model)
@show optimum
