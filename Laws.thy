theory Laws
  imports Axioms
    "HOL-Library.Rewrite"
begin

unbundle lvalue_notation

subsection \<open>Elementary facts\<close>

subsection \<open>Tensor product of homs\<close>

definition "tensor_maps_hom F G = tensor_lift (\<lambda>a b. F a \<otimes> G b)"

lemma maps_2hom_F_tensor_G[simp]:
  assumes \<open>maps_hom F\<close> and \<open>maps_hom G\<close>
  shows \<open>maps_2hom (\<lambda>a b. F a \<otimes> G b)\<close>
proof -
  have \<open>maps_hom (\<lambda>b. F a \<otimes> G b)\<close> for a
    using \<open>maps_hom G\<close> apply (rule comp_maps_hom[of G \<open>\<lambda>b. F a \<otimes> b\<close>, unfolded comp_def])
    using maps_2hom_def tensor_2hom by auto
  moreover have \<open>maps_hom (\<lambda>a. F a \<otimes> G b)\<close> for b
    using \<open>maps_hom F\<close> apply (rule comp_maps_hom[of F \<open>\<lambda>a. a \<otimes> G b\<close>, unfolded comp_def])
    using maps_2hom_def tensor_2hom by auto
  ultimately show ?thesis
    unfolding maps_2hom_def by auto
qed

lemma tensor_maps_hom_hom: "maps_hom F \<Longrightarrow> maps_hom G \<Longrightarrow> maps_hom (tensor_maps_hom F G)"
  unfolding tensor_maps_hom_def apply (rule tensor_lift_hom) by simp

lemma tensor_maps_hom_apply[simp]:
  assumes \<open>maps_hom F\<close> and \<open>maps_hom G\<close>
  shows "tensor_maps_hom F G (a \<otimes> b) = F a \<otimes> G b"
  unfolding tensor_maps_hom_def 
  using tensor_existence maps_2hom_F_tensor_G assms
  by metis


subsection \<open>Pairs and compatibility\<close>

definition compatible :: \<open>('a::domain,'c::domain) maps_hom \<Rightarrow> ('b::domain,'c) maps_hom \<Rightarrow> bool\<close> where
  \<open>compatible F G \<longleftrightarrow> lvalue F \<and> lvalue G \<and> (\<forall>a b. F a \<circ>\<^sub>d G b = G b \<circ>\<^sub>d F a)\<close>

lemma compatibleI:
  assumes "lvalue F" and "lvalue G"
  assumes \<open>\<And>a b. (F a) \<circ>\<^sub>d (G b) = (G b) \<circ>\<^sub>d (F a)\<close>
  shows "compatible F G"
  using assms unfolding compatible_def by simp

lemma compatible_sym: "compatible x y \<Longrightarrow> compatible y x"
  by (simp add: compatible_def)

definition pair :: \<open>('a::domain,'c::domain) maps_hom \<Rightarrow> ('b::domain,'c) maps_hom \<Rightarrow> ('a\<times>'b, 'c) maps_hom\<close> where
  \<open>pair F G = tensor_lift (\<lambda>a b. F a \<circ>\<^sub>d G b)\<close>

lemma maps_2hom_F_comp_G[simp]:
  assumes \<open>maps_hom F\<close> and \<open>maps_hom G\<close>
  shows \<open>maps_2hom (\<lambda>a b. F a \<circ>\<^sub>d G b)\<close>
proof -
  have \<open>maps_hom (\<lambda>b. F a \<circ>\<^sub>d G b)\<close> for a
    using \<open>maps_hom G\<close> apply (rule comp_maps_hom[of G \<open>\<lambda>b. F a \<circ>\<^sub>d b\<close>, unfolded comp_def])
    using maps_2hom_def comp_2hom by auto
  moreover have \<open>maps_hom (\<lambda>a. F a \<circ>\<^sub>d G b)\<close> for b
    using \<open>maps_hom F\<close> apply (rule comp_maps_hom[of F \<open>\<lambda>a. a \<circ>\<^sub>d G b\<close>, unfolded comp_def])
    using maps_2hom_def comp_2hom by auto
  ultimately show ?thesis
    unfolding maps_2hom_def by auto
qed

lemma pair_hom[simp]:
  assumes "maps_hom F" and "maps_hom G"
  shows "maps_hom (pair F G)"
  unfolding pair_def apply (rule tensor_lift_hom) using assms by simp

lemma pair_apply[simp]:
  assumes \<open>maps_hom F\<close> and \<open>maps_hom G\<close>
  shows \<open>(pair F G) (a \<otimes> b) = (F a) \<circ>\<^sub>d (G b)\<close>
  unfolding pair_def 
  using tensor_existence maps_2hom_F_comp_G assms
  by metis

lemma compatible3:
  assumes [simp]: "compatible x y" and "compatible y z" and "compatible x z"
  shows "compatible (pair x y) z"
proof (rule compatibleI)
  have [simp]: \<open>lvalue x\<close> \<open>lvalue y\<close> \<open>lvalue z\<close>
    using assms compatible_def by auto
  then have [simp]: \<open>maps_hom x\<close> \<open>maps_hom y\<close> \<open>maps_hom z\<close>
    using lvalue_hom by blast+
  have "(pair (pair x y) z) ((f \<otimes> g) \<otimes> h) = (pair z (pair x y)) (h \<otimes> (f \<otimes> g))" for f g h
    apply auto using assms unfolding compatible_def
    by (metis comp_domain_assoc)
  then have "(pair (pair x y) z \<circ> swap \<circ> (\<otimes>) h) (f \<otimes> g)
           = (pair z (pair x y) \<circ> (\<otimes>) h) (f \<otimes> g)" for f g h
    by auto
  then have *: "(pair (pair x y) z \<circ> swap \<circ> (\<otimes>) h)
           = (pair z (pair x y) \<circ> (\<otimes>) h)" for h
    by (rule tensor_extensionality)
  have "(pair (pair x y) z) (fg \<otimes> h)
           = (pair z (pair x y)) (h \<otimes> fg)" for fg h
    using *[THEN lvalue_app_fun_cong]
    by auto
  then show "(pair x y fg) \<circ>\<^sub>d (z h) = (z h) \<circ>\<^sub>d (pair x y fg)" for fg h
    unfolding compatible_def by simp
  show "lvalue z" and  "lvalue (pair x y)"
    by simp_all
qed


subsection \<open>Notation\<close>


bundle lvalue_notation begin
unbundle lvalue_notation
notation tensor_maps_hom (infixr "\<otimes>\<^sub>h" 70)
end

bundle no_lvalue_notation begin
unbundle lvalue_notation
no_notation tensor_maps_hom (infixr "\<otimes>\<^sub>h" 70)
end
