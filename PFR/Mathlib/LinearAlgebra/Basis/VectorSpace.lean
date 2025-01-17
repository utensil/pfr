import PFR.Mathlib.Algebra.Module.Submodule.Map
import Mathlib.LinearAlgebra.Basis.VectorSpace

namespace Submodule

variable { B F R : Type* } [DivisionRing R] [AddCommGroup B] [AddCommGroup F]
  [Module R B] [Module R F]

open LinearMap

/-- Given a submodule $E$ of $B \times F$, there is an equivalence $f : E \to B' \times F'$
  given by the projections $E \to B$ and $E \to F$ "modulo" $φ : B \to F$. -/
theorem exists_equiv_fst_sndModFst (E : Submodule R (B × F)) :
    ∃ (B' : Submodule R B) (F' : Submodule R F) (f : E ≃ₗ[R] B' × F') (φ : B →ₗ[R] F),
    (∀ x : E, (f x).1.val = x.val.1 ∧ (f x).2.val = x.val.2 - φ x.val.1) ∧
    (∀ (x₁ : B') (x₂ : F'), (f.symm (x₁, x₂)).val = (x₁.val, x₂.val + φ x₁.val)) := by
  let π₁ := LinearMap.fst R B F
  let f₁ := π₁.submoduleMap E
  have f₁_surj := range_eq_top.mpr (π₁.submoduleMap_surjective E)

  obtain ⟨ φ', hφ' ⟩ := f₁.exists_rightInverse_of_surjective f₁_surj
  obtain ⟨ φ, hφ ⟩ := φ'.exists_extend

  let p₂ := (LinearMap.snd R B F).domRestrict E
  let f₂'' := LinearMap.id - φ'.comp f₁
  let f₂' := p₂.comp f₂''
  let f₂ := f₂'.rangeRestrict

  have h_compl : IsCompl (ker f₁) (ker f₂) := by
    refine IsCompl.of_eq ?_ ?_
    · by_contra hc
      obtain ⟨ x, ⟨ h_ker, h_nezero ⟩ ⟩ := exists_mem_ne_zero_of_ne_bot hc
      rw [mem_inf, mem_ker, mem_ker] at h_ker
      have h_zero₁ : x.val.1 = 0 := Subtype.ext_iff.mp h_ker.left
      have h_zero₂ : x.val.2 = 0 := calc
        x.val.2 = (f₂'' x).val.2 := by
          show _ = (x - φ' (f₁ x)).val.2
          rw [mem_ker.mp h_ker.left, φ'.map_zero, sub_zero]
        _ = 0 := (mk_eq_zero _ _).mp h_ker.right
      exact h_nezero (Subtype.ext (Prod.ext h_zero₁ h_zero₂))
    · apply eq_top_iff'.mpr
      intro x
      apply mem_sup'.mpr
      have : φ x.val.1 = φ' (f₁ x) := by subst hφ ; rfl
      have h_ker₁ : f₂'' x ∈ ker f₁ := by
        apply mem_ker.mpr
        show f₁ x - (f₁.comp φ') (f₁ x) = 0
        rw [hφ'] ; exact sub_self (f₁ x)
      have h_ker₂ : φ x.val.1 ∈ ker f₂ := by
        rewrite [ker_rangeRestrict]
        show p₂ (φ x.val.1 - φ' (f₁ (φ x.val.1))) = 0
        rw [this, ← f₁.comp_apply φ', hφ', LinearMap.id_apply, sub_self, p₂.map_zero]
      use ⟨ f₂'' x, h_ker₁ ⟩, ⟨ φ x.val.1, h_ker₂ ⟩
      simp only
      rewrite [← hφ]
      exact sub_add_cancel x (φ x.val.1)

  let f := equivProdOfSurjectiveOfIsCompl f₁ f₂ f₁_surj f₂'.range_rangeRestrict h_compl
  use E.map π₁, range f₂', f, p₂.comp φ
  constructor
  · intro _
    rw [equivProdOfSurjectiveOfIsCompl_apply]
    constructor ; rfl ; subst hφ ; rfl
  · intro x₁ x₂
    let x : E := f.symm (x₁, x₂)
    have hf : f₁ x = x₁ ∧ f₂ x = x₂ := (Prod.mk.injEq _ _ _ _).mp (f.apply_symm_apply (x₁, x₂))
    have : (f₂ x).val = x.val.2 - p₂ (φ x.val.1) := by subst hφ ; rfl
    have : x₂.val + p₂ (φ x.val.1) = x.val.2 :=
      eq_sub_iff_add_eq.mp (Eq.trans (Subtype.ext_iff.mp hf.right).symm this)
    show x.val = _
    rw [← hf.left]
    exact (Prod.mk.injEq _ _ _ _).mpr ⟨ rfl (a := x.val.1), this.symm ⟩
