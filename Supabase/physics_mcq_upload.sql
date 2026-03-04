-- Bulk Insert Physics-I (BS-PH101) MCQs
-- This script multiplexes the questions across all departments sharing the paper code.

INSERT INTO public.mock_test_questions (department, semester, subject, paper_code, question_text, options, correct_index)
SELECT 
    sb.department, 
    sb.semester, 
    sb.subject, 
    'BS-PH101',
    q.question,
    q.opts,
    q.ans
FROM public.subjects_bundle sb
CROSS JOIN (
    VALUES 
    ('Phase difference between displacement and velocity in SHM is:', ARRAY['0', 'π/4', 'π/2', 'π'], 2),
    ('For large damping constant, the resonance curve becomes:', ARRAY['Sharp', 'Broad', 'Infinite', 'Zero'], 1),
    ('Superposition of two SHMs of equal amplitude and phase difference π/2 gives:', ARRAY['Ellipse', 'Circle', 'Straight line', 'Hyperbola'], 1),
    ('Fringe width in Young’s double slit experiment is:', ARRAY['λd/D', 'Dλ/d', 'dλ/D', 'λ/Dd'], 1),
    ('In Fraunhofer diffraction, the incident wavefront is:', ARRAY['Cylindrical', 'Plane', 'Spherical', 'Random'], 1),
    ('Polarization proves that light waves are:', ARRAY['Longitudinal', 'Transverse', 'Mechanical', 'Stationary'], 1),
    ('Dispersive power of a grating increases with increase in:', ARRAY['Slit width', 'Wavelength', 'Number of lines per unit length', 'Screen distance'], 2),
    ('Population inversion means:', ARRAY['Equal populations in levels', 'More atoms in ground state', 'More atoms in excited state', 'No excitation'], 2),
    ('In Ruby laser, population inversion is achieved by:', ARRAY['Electrical discharge', 'Optical pumping', 'Heating', 'Chemical reaction'], 1),
    ('Compton wavelength is given by:', ARRAY['h/mc', 'h/mv', 'mc/h', 'hv/m'], 0),
    ('Pauli exclusion principle is valid in:', ARRAY['MB statistics', 'BE statistics', 'FD statistics', 'Classical statistics'], 2),
    ('At absolute zero, probability of occupancy above Fermi level is:', ARRAY['1', '0', '1/2', 'Infinite'], 1),
    ('If energy is measured accurately, uncertainty in time becomes:', ARRAY['Zero', 'Infinite', 'Constant', 'Negative'], 1),
    ('MB statistics is applicable for photons:', ARRAY['True', 'False', 'Only at 0K', 'Sometimes'], 1),
    ('Planck’s radiation law is derived using:', ARRAY['MB statistics', 'FD statistics', 'BE statistics', 'Classical theory'], 2),
    ('Emissivity of an ideal black body is:', ARRAY['0', '0.5', '1', 'Infinity'], 2),
    ('According to Wien’s displacement law, λmax T equals:', ARRAY['Constant', 'Zero', 'Infinity', 'Variable'], 0),
    ('Curl of a conservative vector field is:', ARRAY['1', '−1', '0', '∞'], 2),
    ('Divergence of magnetic flux density B is:', ARRAY['1', '0', '−1', '∞'], 1),
    ('∇·r⃗ equals:', ARRAY['1', '2', '3', '0'], 2),
    ('Displacement current arises due to: ', ARRAY['Static charge', 'Changing magnetic field', 'Changing electric field', 'Constant current'], 2),
    ('Differential form of Faraday’s law is:', ARRAY['∇·E = 0', '∇×E = −∂B/∂t', '∇·B = 0', '∇×B = 0'], 1),
    ('Kinetic energy of charge q accelerated through potential V is:', ARRAY['q/V', 'qV', 'V/q', 'q²V'], 1),
    ('Example of a uniaxial crystal is:', ARRAY['Glass', 'Calcite', 'Iron', 'Copper'], 1),
    ('Miller indices for intercepts 2, 3, 4 are:', ARRAY['(2 3 4)', '(1/2 1/3 1/4)', '(6 4 3)', '(4 3 2)'], 2),
    ('Relativistic energy-momentum relation is:', ARRAY['E² = p²c² + m²c⁴', 'E = mc²', 'E = pc', 'E = p²/2m'], 0),
    ('Degrees of freedom of a system is:', ARRAY['N + K', '3N − K', 'N − K', '3N + K'], 1),
    ('Angular momentum is conserved when:', ARRAY['Force is zero', 'Torque is zero', 'Velocity is zero', 'Energy is zero'], 1),
    ('Phase velocity equals group velocity when the medium is:', ARRAY['Dispersive', 'Non-dispersive', 'Absorbing', 'Conducting'], 1)
) AS q(question, opts, ans)
WHERE sb.paper_code = 'BS-PH101';
