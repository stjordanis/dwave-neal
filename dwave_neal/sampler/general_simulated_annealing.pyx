from libcpp.vector cimport vector
cimport numpy as np
import numpy as np

__all__ = ["simulated_annealing"]

"""Cython wrapper for C++ simulated annealing solver"""

cdef extern from "cpu_sa.h":
    vector[double] general_simulated_annealing(
            char*, # giant array that holds all states
            const int, # number of samples
            vector[double] &, # h
            vector[int] &, # coupler starts
            vector[int] &, # coupler ends
            vector[double] &, # coupler weights
            int, # sweeps per beta
            vector[double] &, # beta schedule
            unsigned long long) # seed

def simulated_annealing(num_samples, h, coupler_starts, coupler_ends, 
                        coupler_weights, sweeps_per_beta, beta_schedule, seed):
    """Wraps `general_simulated_annealing` from `cpu_sa.cpp`. Accepts
    an Ising problem defined on a general graph and returns samples
    using simulated annealing.

    Parameters
    ----------
    num_samples : int
        Number of samples to get from the sampler.

    h : list(float)
        The h or field values for the problem.

    coupler_starts : list(int)
        A list of the start variable of each coupler. For a problem
        with the couplers (0, 1), (1, 2), and (3, 1), `coupler_starts`
        should be [0, 1, 3].

    coupler_ends : list(int)
        A list of the end variable of each coupler. For a problem
        with the couplers (0, 1), (1, 2), and (3, 1), `coupler_ends`
        should be [1, 2, 1].

    coupler_weights : list(float)
        A list of the J values or weight on each coupler, in the same
        order as `coupler_starts` and `coupler_ends`.

    sweeps_per_beta : int
        The number of sweeps to perform at each beta value provided in 
        `beta_schedule`. The total number of sweeps per sample is 
        sweeps_per_beta * len(beta_schedule).

    beta_schedule : list(float)
        A list of the different beta values to run sweeps at. 

    seed : 64 bit int > 0
        The seed to use for the PRNG. Must be a positive integer
        greater than 0. If the same seed is used and the rest of the
        parameters are the same, the returned samples will be
        identical.

    Returns
    -------
    samples : numpy.ndarray
        Returns a 2d numpy array of shape (num_samples

    """

    num_vars = len(h)

    # in the case that we either need no samples or there are no variables,
    # we can safely return an empty array (and set energies to 0)
    if num_samples*num_vars == 0:
        annealed_states = np.empty((num_samples, num_vars), dtype=np.int8)
        return annealed_states, np.zeros(num_samples, dtype=np.double)


    cdef np.ndarray[char, ndim=1, mode="c"] states_numpy = \
            np.empty(num_samples*num_vars, dtype="b")
    cdef char* states = &states_numpy[0]
    
    energies = general_simulated_annealing(states, num_samples, h, 
                                           coupler_starts, coupler_ends, 
                                           coupler_weights, 
                                           sweeps_per_beta, beta_schedule, 
                                           seed)

    annealed_states = states_numpy.reshape((num_samples, num_vars))

    return annealed_states, np.asarray(energies)
