# Finite-State Machine

## A Finite State Machine is defined by (Σ,S,s0,δ,F), where:
  - Σ is the input alphabet (a finite, non-empty set of symbols).
  - S is a finite, non-empty set of states.
  - s0 is an initial state, an element of S.
  - δ is the state-transition function: δ : S x Σ → S
  - F is the set of final states, a (possibly empty) subset of S.
  - O is the set (possibly empty) of outputs

## Example (Ticket Machine):
  - Σ (m, t, r) : inserting money, requesting ticket, requesting refund
  - S (1, 2) : unpaid, paid
  - s0 (1) : an initial state, an element of S.
  - δ () : (here should have been an image...)
  - F : empty
  - O (p/d) : print ticket, deliver refund 


## Learning materials
- Stanford CS123: https://web.stanford.edu/class/cs123/lectures/CS123_lec07_Finite_State_Machine.pdf
- Newcastle University: https://research.ncl.ac.uk/game/mastersdegree/gametechnologies/previousinformation/artificialintelligence1finitestatemachines/2016%20Tutorial%208%20-%20Finite%20State%20Machines.pdf
- More Newcastle University: https://research.ncl.ac.uk/game/mastersdegree/gametechnologies/aitutorials/1state-basedai/AI%20-%20State%20Machines.pdf
- 42 ecole
