theory QHoare
  imports Quantum2
begin


locale qhoare =
  fixes memory_type :: "'mem::finite itself"
begin

definition "apply U R = R U" for R :: \<open>('a,'mem) maps_hom\<close>
definition "ifthen R x = R (butterket x x)" for R :: \<open>('a,'mem) maps_hom\<close>
definition "program S = fold (o\<^sub>C\<^sub>L) S idOp" for S :: \<open>'mem domain_end list\<close>


definition hoare :: \<open>'mem ell2 clinear_space \<Rightarrow> ('mem ell2 \<Rightarrow>\<^sub>C\<^sub>L 'mem ell2) list \<Rightarrow> 'mem ell2 clinear_space \<Rightarrow> bool\<close> where
  "hoare C p D \<longleftrightarrow> (\<forall>\<psi>\<in>space_as_set C. program p *\<^sub>V \<psi> \<in> space_as_set D)" for C p D

definition "EQP R \<psi> = R (selfbutter \<psi>)" for R :: \<open>('a,'mem) maps_hom\<close>
definition "EQ R \<psi> = EQP R \<psi> *\<^sub>S \<top>" for R :: \<open>('a,'mem) maps_hom\<close>

lemma swap_EQP:
  assumes "compatible R S"
  shows "EQP R \<psi> o\<^sub>C\<^sub>L EQP S \<phi> = EQP S \<phi> o\<^sub>C\<^sub>L EQP R \<psi>"
  unfolding EQP_def
  by (rule swap_lvalues[OF assms])

lemma swap_EQP':
  assumes "compatible R S"
  shows "EQP R \<psi> o\<^sub>C\<^sub>L (EQP S \<phi> o\<^sub>C\<^sub>L C) = EQP S \<phi> o\<^sub>C\<^sub>L (EQP R \<psi> o\<^sub>C\<^sub>L C)"
  by (simp add: assms assoc_left(1) swap_EQP)

lemma join_EQP:
  assumes [compatible]: "compatible R S"
  shows "EQP R \<psi> o\<^sub>C\<^sub>L EQP S \<phi> = EQP (pair R S) (\<psi> \<otimes>\<^sub>s \<phi>)"
  unfolding EQP_def
  apply (subst pair_apply[symmetric, where F=R and G=S])
  using assms by auto

lemma join_EQP':
  assumes "compatible R S"
  shows "EQP R \<psi> o\<^sub>C\<^sub>L (EQP S \<phi> o\<^sub>C\<^sub>L C) = EQP (pair R S) (\<psi> \<otimes>\<^sub>s \<phi>) o\<^sub>C\<^sub>L C"
  by (simp add: assms assoc_left(1) join_EQP)

lemma program_seq: "program (p1@p2) = program p2 o\<^sub>C\<^sub>L program p1"
  apply (induction p1)
  unfolding program_def
   apply auto
  sorry


lemma hoare_seq[trans]: "hoare C p1 D \<Longrightarrow> hoare D p2 E \<Longrightarrow> hoare C (p1@p2) E"
  by (auto simp: program_seq hoare_def times_applyOp)

lemma hoare_skip: "C \<le> D \<Longrightarrow> hoare C [] D"
  by (auto simp: program_def hoare_def times_applyOp in_mono less_eq_clinear_space.rep_eq)

lemma hoare_apply: 
  assumes "R U *\<^sub>S pre \<le> post"
  shows "hoare pre [apply U R] post"
  using assms 
  apply (auto simp: hoare_def program_def apply_def)
  by (metis (no_types, lifting) applyOpSpace.rep_eq closure_subset imageI less_eq_clinear_space.rep_eq subsetD)

lemma hoare_ifthen: 
  fixes R :: \<open>('a,'mem) maps_hom\<close>
  assumes "EQP R (ket x) *\<^sub>S pre \<le> post"
  shows "hoare pre [ifthen R x] post"
  using assms 
  apply (auto simp: hoare_def program_def ifthen_def EQP_def butterfly_def')
  by (metis (no_types, lifting) applyOpSpace.rep_eq closure_subset imageI less_eq_clinear_space.rep_eq subsetD)

end

end
