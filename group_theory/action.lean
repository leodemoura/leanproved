import algebra.group data.set data.fintype .extra

namespace algebra
namespace group
section perm
open set function eq.ops
variable {A : Type}
structure perm (A : Type) : Type :=
(f : A → A) (is_perm : @bijective A A f)
attribute perm.f [coercion]

definition perm.compose (g f : perm A) : perm A := 
  perm.mk (g∘f) (bijective_compose (perm.is_perm g) (perm.is_perm f))

local infix `^` := perm.compose
theorem perm.assoc (h g f : perm A) : h ^ g ^ f = h ^ (g ^ f) := rfl
reveal perm.assoc

check @eq.rec_on
definition perm.one : perm A := perm.mk id id_is_bij
lemma perm.one_mul (f : perm A) : perm.one ^ f = f :=
      perm.cases_on f (λ f Hf, rfl)

-- to construct an inv we need to go finite
example : semigroup (perm A) := @semigroup.mk (perm A) perm.compose perm.assoc
end perm
section finperm
variable {A : Type}
variable [FinA : fintype A]
include FinA

definition find_inv (f : perm A) : A → A := sorry
  
definition perm.inv (f : perm A) : perm A := sorry
  
end finperm


end group
end algebra
