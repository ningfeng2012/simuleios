#=-------------splitstep.jl----------------------------------------------------#
#
#              split step method for macroscopic wave function generation
#
# Purpose: This file is intended to create a splitstep method for BEC systems.
#          Eventually we may incorporate real-time evolution, but we need to 
#          first generate the grounds state and go from there.
#
#   Notes: Units of hbar = c  = 1
#-----------------------------------------------------------------------------=#

global xmax = 5

# This initializes the potential well and also the gaussian init wavefunction
function initialize(res)
    gaus = zeros(res)
    pot = zeros(res)
    for dx = 1:res
        x = dx * (xmax/res) - xmax / 2
        gaus[dx] = exp(-x * x )
        pot[dx] = x * x
        #println(gaus[dx], '\t', pot[dx], '\t', x)
    end
    return gaus, pot
end

# This will return the kinetic and potential energies at every timestep
# Note unphysical units will be fixed in the future.
function energy(wave, pot, dt, res)

    #ficticious g for now
    PE = zeros(size(wave,1))
    KE = zeros(size(wave,1))
    dk = 2pi / res

    for i = 1:size(wave,1)

        k = dk * (i - (size(wave,1) / 2))

        PE[i] = exp( (pot[i] + wave[i]*wave[i]) *dt)

        # KE relies on k, not yet determined
        KE[i] = exp( (k*k) * dt)
    end
    return PE, KE
end

# The whole shebang
# Psi * Uv -> fft -> Psi * Uk -> ifft -> renormalization -> cycle
function splitstep(res)

    output = open("out.dat", "w")
    wave, pot = initialize(res)

    for j = 1:100

        PE, KE = energy(wave, pot, 0.1, res)
 
        for i = 1:res
            wave[i] *= PE[i]
        end
 
        wave = fft(wave)

        for i = 1:res
            wave[i] *= KE[i]
        end

        wave = abs(ifft(wave))

        norm_const = 0.0
        for i = 1:res
            norm_const += wave[i]
        end

        println(norm_const)

        wave *= 1/norm_const

        #if j % 100 == 0
            for i = 1:res
                println(output, wave[i])
            end

            print(output, '\n', '\n')
        #end

    end
end

# Main

splitstep(100)