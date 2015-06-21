/-
Copyright (c) 2015 Haitao Zhang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author : Haitao Zhang
-/

-- develop the concept of finite subgroups based on finsets so that the properties
-- can be used directly without translating from the set based theory first

import data algebra.group algebra.group_power data .subgroup .finfun .hom
open function algebra set finset
-- ⁻¹ in eq.ops conflicts with group ⁻¹
open eq.ops

namespace group
open ops

section subg
-- we should be able to prove properties using finsets directly
variable {G : Type}
variable [ambientG : group G]
include ambientG

definition finset_mul_closed_on [reducible] (H : finset G) : Prop :=
           ∀ (x y : G), x ∈ H → y ∈ H → x * y ∈ H
definition finset_has_inv (H : finset G) : Prop :=
           ∀ (a : G), a ∈ H → a⁻¹ ∈ H
structure is_finsubg [class] (H : finset G) : Type :=
          (has_one : 1 ∈ H)
          (mul_closed : finset_mul_closed_on H)
          (has_inv : finset_has_inv H)

check @finset.univ
definition univ_is_finsubg [instance] [finG : fintype G] : is_finsubg (@finset.univ G _) :=
is_finsubg.mk !mem_univ (λ x y Px Py, !mem_univ) (λ a Pa, !mem_univ)

lemma finsubg_has_one (H : finset G) [h : is_finsubg H] : 1 ∈ H :=
      @is_finsubg.has_one G _ H h
lemma finsubg_mul_closed (H : finset G) [h : is_finsubg H] : finset_mul_closed_on H :=
      @is_finsubg.mul_closed G _ H h
lemma finsubg_has_inv (H : finset G) [h : is_finsubg H] : finset_has_inv H :=
      @is_finsubg.has_inv G _ H h

variable [deceqG : decidable_eq G]
include deceqG

definition finsubg_to_subg [instance] {H : finset G} [h : is_finsubg H]
         : is_subgroup (ts H) :=
           is_subgroup.mk
           (mem_eq_mem_to_set H 1 ▸ finsubg_has_one H)
           (take x y, begin repeat rewrite -mem_eq_mem_to_set,
             apply finsubg_mul_closed H end)
           (take a, begin repeat rewrite -mem_eq_mem_to_set,
             apply finsubg_has_inv H end)
end subg

section lagrange
-- this is work based on is_subgroup. will test is_finsubg somewhere else first.
variable {A : Type}
variable [deceq : decidable_eq A]
include deceq
variable [s : group A]
include s

definition fin_lcoset (H : finset A) (a : A) := finset.image (lmul_by a) H
definition fin_lcosets (H G : finset A) := image (fin_lcoset H) G

variable {H : finset A}

lemma fin_lcoset_eq (a : A) : ts (fin_lcoset H a) = a ∘> (ts H) := calc
      ts (fin_lcoset H a) = coset.l a (ts H) : to_set_image
      ... = a ∘> (ts H) : glcoset_eq_lcoset
lemma fin_lcoset_card (a : A) : card (fin_lcoset H a) = card H :=
      card_image_eq_of_inj_on (lmul_inj_on a (ts H))
lemma fin_lcosets_card_eq {G : finset A} : ∀ gH, gH ∈ fin_lcosets H G → card gH = card H :=
      take gH, assume Pcosets, obtain g Pg, from exists_of_mem_image Pcosets,
      and.right Pg ▸ fin_lcoset_card g

variable [is_subgH : is_subgroup (to_set H)]
include is_subgH

lemma fin_lcoset_same (x a : A) : x ∈ (fin_lcoset H a) = (fin_lcoset H x = fin_lcoset H a) :=
      begin
        rewrite mem_eq_mem_to_set,
        rewrite [eq_eq_to_set_eq, *(fin_lcoset_eq x), fin_lcoset_eq a],
        exact (subg_lcoset_same x a)
      end
lemma fin_mem_lcoset (g : A) : g ∈ fin_lcoset H g :=
      have P : g ∈ g ∘> ts H, from and.left (subg_in_coset_refl g),
      assert P1 : g ∈ ts (fin_lcoset H g), from eq.symm (fin_lcoset_eq g) ▸ P,
      eq.symm (mem_eq_mem_to_set _ g) ▸ P1
lemma fin_lcoset_subset {S : finset A} (Psub : S ⊆ H) : ∀ x, x ∈ H → fin_lcoset S x ⊆ H :=
      assert Psubs : set.subset (ts S) (ts H), from subset_eq_to_set_subset S H ▸ Psub,
      take x, assume Pxs : x ∈ ts H,
      assert Pcoset : set.subset (x ∘> ts S) (ts H), from subg_lcoset_subset_subg Psubs x Pxs,
      by rewrite [subset_eq_to_set_subset, fin_lcoset_eq x]; exact Pcoset

variable {G : finset A}
variable [is_subgG : is_subgroup (to_set G)]
include is_subgG

open finset.partition

definition fin_lcoset_partition_subg (Psub : H ⊆ G) :=
      partition.mk G (fin_lcoset H) fin_lcoset_same
        (restriction_imp_union (fin_lcoset H) fin_lcoset_same (fin_lcoset_subset Psub))

open nat

theorem lagrange_theorem (Psub : H ⊆ G) : card G = card (fin_lcosets H G) * card H := calc
        card G = nat.Sum (fin_lcosets H G) card : class_equation (fin_lcoset_partition_subg Psub)
        ... = nat.Sum (fin_lcosets H G) (λ x, card H) : nat.Sum_ext (take g P, fin_lcosets_card_eq g P)
        ... = card (fin_lcosets H G) * card H : Sum_const_eq_card_mul

end lagrange

section cyclic
open nat fin

definition mk_mod (n i : nat) : fin (succ n) :=
mk (i mod (succ n)) (mod_lt _ !zero_lt_succ)

definition diff [reducible] (i j : nat) :=
if (i < j) then (j - i) else (i - j)

lemma diff_eq_dist {i j : nat} : diff i j = dist i j :=
#nat decidable.by_cases
  (λ Plt : i < j,
    by rewrite [if_pos Plt, ↑dist, sub_eq_zero_of_le (le_of_lt Plt), zero_add])
  (λ Pnlt : ¬ i < j,
    by rewrite [if_neg Pnlt, ↑dist, sub_eq_zero_of_le (le_of_not_gt Pnlt)])

lemma diff_eq_max_sub_min {i j : nat} : diff i j = (max i j) - min i j :=
decidable.by_cases
  (λ Plt : i < j, begin rewrite [↑max, ↑min, *(if_pos Plt)] end)
  (λ Pnlt : ¬ i < j, begin rewrite [↑max, ↑min, *(if_neg Pnlt)] end)

lemma diff_succ {i j : nat} : diff (succ i) (succ j) = diff i j :=
by rewrite [*diff_eq_dist, ↑dist, *succ_sub_succ]

lemma diff_add {i j k : nat} : diff (i + k) (j + k) = diff i j :=
by rewrite [*diff_eq_dist, dist_add_add_right]

lemma diff_le_max {i j : nat} : diff i j ≤ max i j :=
begin rewrite diff_eq_max_sub_min, apply sub_le end

lemma diff_gt_zero_of_ne {i j : nat} : i ≠ j → diff i j > 0 :=
assume Pne, decidable.by_cases
  (λ Plt : i < j, begin rewrite [if_pos Plt], apply sub_pos_of_lt Plt end)
  (λ Pnlt : ¬ i < j, begin
    rewrite [if_neg Pnlt], apply sub_pos_of_lt,
    apply lt_of_le_and_ne (nat.le_of_not_gt Pnlt) (ne.symm Pne) end)

lemma max_lt_of_lt_of_lt {i j n : nat} : i < n → j < n → max i j < n :=
assume Pilt Pjlt, decidable.by_cases
  (λ Plt : i < j, by rewrite [↑max, if_pos Plt]; exact Pjlt)
  (λ Pnlt : ¬ i < j, by rewrite [↑max, if_neg Pnlt]; exact Pilt)

lemma max_lt {n : nat} (i j : fin n) : max i j < n :=
max_lt_of_lt_of_lt (is_lt i) (is_lt j)

variable {A : Type}

open list
lemma zero_lt_length_of_mem {a : A} : ∀ {l : list A}, a ∈ l → 0 < length l
| []     := assume Pinnil, by contradiction
| (b::l) := assume Pin, !zero_lt_succ

variable [ambG : group A]
include ambG

lemma pow_mod {a : A} {n m : nat} : a ^ m = 1 → a ^ n = a ^ (n mod m) :=
assume Pid,
have Pm : a ^ (n div m * m) = 1, from calc
  a ^ (n div m * m) = a ^ (m * (n div m)) : {mul.comm (n div m) m}
                ... = (a ^ m) ^ (n div m) : !pow_mul
                ... = 1 ^ (n div m) : {Pid}
                ... = 1 : one_pow (n div m),
calc a ^ n = a ^ (n div m * m + n mod m) : {eq_div_mul_add_mod n m}
       ... = a ^ (n div m * m) * a ^ (n mod m) : !pow_add
       ... = 1 * a ^ (n mod m) : {Pm}
       ... = a ^ (n mod m) : !one_mul

lemma pow_sub_eq_one_of_pow_eq {a : A} {i j : nat} :
  a^i = a^j → a^(i - j) = 1 :=
assume Pe, or.elim (lt_or_ge i j)
  (assume Piltj, begin rewrite [sub_eq_zero_of_le (nat.le_of_lt Piltj)] end)
  (assume Pigej, begin rewrite [pow_sub a Pigej, Pe, mul.right_inv] end)

lemma pow_diff_eq_one_of_pow_eq {a : A} {i j : nat} :
  a^i = a^j → a^(diff i j) = 1 :=
assume Pe, decidable.by_cases
  (λ Plt : i < j, by rewrite [if_pos Plt]; exact pow_sub_eq_one_of_pow_eq (eq.symm Pe))
  (λ Pnlt : ¬ i < j, by rewrite [if_neg Pnlt]; exact pow_sub_eq_one_of_pow_eq Pe)

lemma pow_madd {a : A} {n : nat} {i j : fin (succ n)} :
  a^(succ n) = 1 → a^(val (i + j)) = a^i * a^j :=
assume Pe, calc
a^(val (i + j)) = a^((i + j) mod (succ n)) : rfl
            ... = a^(i + j) : pow_mod Pe
            ... = a^i * a^j : !pow_add

lemma mk_pow_mod {a : A} {n m : nat} : a ^ (succ m) = 1 → a ^ n = a ^ (mk_mod m n) :=
assume Pe, pow_mod Pe

variable [finA : fintype A]
include finA

open fintype

lemma card_pos : 0 < card A :=
  zero_lt_length_of_mem (mem_univ 1)

variable [deceqA : decidable_eq A]
include deceqA

lemma exists_pow_eq_one (a : A) : ∃ n, n < card A ∧ a ^ (succ n) = 1 :=
let f := (λ i : fin (succ (card A)), a ^ i) in
assert Pninj : ¬(injective f), from assume Pinj,
  absurd (card_le_of_inj _ _ (exists.intro f Pinj))
    (begin rewrite [card_fin], apply not_succ_le_self end),
obtain i₁ P₁, from exists_not_of_not_forall Pninj,
obtain i₂ P₂, from exists_not_of_not_forall P₁,
obtain Pfe Pne, from iff.elim_left not_implies_iff_and_not P₂,
assert Pvne : val i₁ ≠ val i₂, from assume Pveq, absurd (eq_of_veq Pveq) Pne,
exists.intro (pred (diff i₁ i₂)) (begin
  rewrite [succ_pred_of_pos (diff_gt_zero_of_ne Pvne)], apply and.intro,
    apply lt_of_succ_lt_succ,
    rewrite [succ_pred_of_pos (diff_gt_zero_of_ne Pvne)],
    apply nat.lt_of_le_of_lt diff_le_max (max_lt i₁ i₂),
    apply pow_diff_eq_one_of_pow_eq Pfe
  end)

-- Another possibility is to generate a list of powers and use find to get the first
-- unity.
-- The bound on bex is arbitrary as long as it is large enough (at least card A). Making
-- it larger simplifies some proofs, such as a ∈ cyc a.
definition cyc (a : A) : finset A := {x ∈ univ | bex (succ (card A)) (λ n, a ^ n = x)}

definition order (a : A) := card (cyc a)

definition pow_fin (a : A) (n : nat) (i : fin (order a)) := pow a (i + n)

definition cyc_pow_fin (a : A) (n : nat) : finset A := image (pow_fin a n) univ

lemma order_le_group_order {a : A} : order a ≤ card A :=
card_le_card_of_subset !subset_univ

lemma cyc_has_one (a : A) : 1 ∈ cyc a :=
begin
  apply mem_filter_of_mem !mem_univ,
  existsi 0, apply and.intro,
    apply zero_lt_succ,
    apply pow_zero
end

lemma order_pos (a : A) : 0 < order a :=
zero_lt_length_of_mem (cyc_has_one a)

lemma cyc_mul_closed (a : A) : finset_mul_closed_on (cyc a) :=
take g h, assume Pgin Phin,
obtain n Plt Pe, from exists_pow_eq_one a,
obtain i Pilt Pig, from of_mem_filter Pgin,
obtain j Pjlt Pjh, from of_mem_filter Phin,
begin
  rewrite [-Pig, -Pjh, -pow_add, pow_mod Pe],
  apply mem_filter_of_mem !mem_univ,
  existsi ((i + j) mod (succ n)), apply and.intro,
    apply nat.lt.trans (mod_lt (i+j) !zero_lt_succ) (succ_lt_succ Plt),
    apply rfl
end

lemma cyc_has_inv (a : A) : finset_has_inv (cyc a) :=
take g, assume Pgin,
obtain n Plt Pe, from exists_pow_eq_one a,
obtain i Pilt Pig, from of_mem_filter Pgin,
let ni := -(mk_mod n i) in
assert Pinv : g*a^ni = 1, by
  rewrite [-Pig, mk_pow_mod Pe, -(pow_madd Pe), add.right_inv],
begin
  rewrite [inv_eq_of_mul_eq_one Pinv],
  apply mem_filter_of_mem !mem_univ,
  existsi ni, apply and.intro,
    apply nat.lt.trans (is_lt ni) (succ_lt_succ Plt),
    apply rfl
end

lemma self_mem_cyc (a : A) : a ∈ cyc a :=
mem_filter_of_mem !mem_univ
  (exists.intro (1 : nat) (and.intro (succ_lt_succ card_pos) !pow_one))

lemma mem_cyc (a : A) : ∀ {n : nat}, a^n ∈ cyc a
| 0        := cyc_has_one a
| (succ n) :=
  begin rewrite pow_succ, apply cyc_mul_closed a, exact mem_cyc, apply self_mem_cyc end

lemma order_le {a : A} {n : nat} : a^(succ n) = 1 → order a ≤ succ n :=
assume Pe, let s := image (pow a) (upto (succ n)) in
assert Psub: cyc a ⊆ s, from subset_of_forall
  (take g, assume Pgin, obtain i Pilt Pig, from of_mem_filter Pgin, begin
  rewrite [-Pig, pow_mod Pe],
  apply mem_image_of_mem_of_eq,
    apply mem_upto_of_lt (mod_lt i !zero_lt_succ),
    exact rfl end),
#nat calc order a ≤ card s : card_le_card_of_subset Psub
              ... ≤ card (upto (succ n)) : !card_image_le
              ... = succ n : card_upto (succ n)

lemma pow_ne_of_lt_order {a : A} {n : nat} : succ n < order a → a^(succ n) ≠ 1 :=
assume Plt, not_imp_not_of_imp order_le (nat.not_le_of_gt Plt)

lemma eq_zero_of_pow_eq_one {a : A} : ∀ {n : nat}, a^n = 1 → n < order a → n = 0
| 0        := assume Pe Plt, rfl
| (succ n) := assume Pe Plt, absurd Pe (pow_ne_of_lt_order Plt)

lemma pow_fin_inj (a : A) (n : nat) : injective (pow_fin a n) :=
take i j, assume Peq : a^(i + n) = a^(j + n),
have Pde : a^(diff i j) = 1, from diff_add ▸ pow_diff_eq_one_of_pow_eq Peq,
have Pdz : diff i j = 0, from eq_zero_of_pow_eq_one Pde
  (nat.lt_of_le_of_lt diff_le_max (max_lt i j)),
eq_of_veq (eq_of_dist_eq_zero (diff_eq_dist ▸ Pdz))

lemma cyc_eq_cyc (a : A) (n : nat) : cyc_pow_fin a n = cyc a :=
assert Psub : cyc_pow_fin a n ⊆ cyc a, from subset_of_forall
  (take g, assume Pgin,
  obtain i Pin Pig, from exists_of_mem_image Pgin, by rewrite [-Pig]; apply mem_cyc),
eq_of_card_eq_of_subset (begin apply eq.trans,
    apply card_image_eq_of_inj_on,
      rewrite [to_set_univ, -injective_iff_inj_on_univ], exact pow_fin_inj a n,
    rewrite [card_fin] end) Psub

lemma pow_order (a : A) : a^(order a) = 1 :=
obtain i Pin Pone, from exists_of_mem_image (eq.symm (cyc_eq_cyc a 1) ▸ cyc_has_one a),
or.elim (eq_or_lt_of_le (succ_le_of_lt (is_lt i)))
  (assume P, P ▸ Pone) (assume P, absurd Pone (pow_ne_of_lt_order P))

definition cyc_is_finsubg [instance] (a : A) : is_finsubg (cyc a) :=
is_finsubg.mk (cyc_has_one a) (cyc_mul_closed a) (cyc_has_inv a)

lemma order_dvd_group_order (a : A) : order a ∣ card A :=
dvd.intro (eq.symm (!mul.comm ▸ lagrange_theorem (subset_univ (cyc a))))

definition pow_fin' (a : A) (n : nat) (i : fin (succ (pred (order a)))) := pow a (i + n)

local attribute group_of_add_group [instance]

lemma pow_fin_hom (a : A) : homomorphic (pow_fin' a 0) :=
take i j,
begin
  rewrite [↑pow_fin', *nat.add_zero],
  apply pow_madd,
  rewrite [succ_pred_of_pos !order_pos],
  exact pow_order a
end

definition pow_fin_is_iso (a : A) : is_iso_class (pow_fin' a 0) :=
is_iso_class.mk (pow_fin_hom a)
  (begin rewrite [↑pow_fin', succ_pred_of_pos !order_pos], exact pow_fin_inj a 0 end)

end cyclic

end group
