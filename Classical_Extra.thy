section \<open>Derived facts about classical lvalues\<close>

theory Classical_Extra
  imports Laws_Classical
begin

no_notation m_inv ("inv\<index> _" [81] 80)

lemma lvalue_single_valued:
  assumes lvalueF: \<open>lvalue F\<close>
  assumes single: \<open>single_valued a\<close>
  shows \<open>single_valued (F a)\<close>
proof -
  have "mono F"
    by (simp add: lvalueF lvalue_hom update_hom_mono)
  
  from single
  have contains_Id: "a\<inverse> O a \<subseteq> Id"
    by (auto simp add: single_valued_def)

  have "(F a)\<inverse> O F a = F (a\<inverse> O a)"
    by (metis lvalueF lvalue_def)
  also have \<open>\<dots> \<subseteq> F Id\<close>
    using \<open>mono F\<close> contains_Id
    by (meson monoD)
  also have \<open>\<dots> = Id\<close>
    using lvalueF lvalue_def by blast
  
  finally show "single_valued (F a)"
    by (auto simp: single_valued_def)
qed



lemma lvalue_fulldom:
  assumes lvalueF: \<open>lvalue F\<close>
  assumes adom: \<open>Domain a = UNIV\<close>
  shows \<open>Domain (F a) = UNIV\<close>
proof -
  have "mono F"
    by (simp add: lvalueF lvalue_hom update_hom_mono)
  
  from adom
  have contains_Id: "a O a\<inverse> \<supseteq> Id"
    by (auto simp add: converse_def relcomp_def relcompp_apply)
  
  have "F a O (F a)\<inverse> = F (a O a\<inverse>)"
    by (metis lvalueF lvalue_def)
  also have \<open>\<dots> \<supseteq> F Id\<close> (is \<open>_ \<supseteq> \<dots>\<close>)
    using \<open>mono F\<close> contains_Id
    by (meson monoD)
  also have \<open>\<dots> = Id\<close>
    using lvalueF lvalue_def by blast
  
  finally show "Domain (F a) = UNIV"
    by auto
qed


lemma lvalue_fullrange:
  assumes lvalueF: \<open>lvalue F\<close>
  assumes arange: \<open>Range a = UNIV\<close>
  shows \<open>Range (F a) = UNIV\<close>
  using lvalue_fulldom[OF lvalueF arange[folded Domain_converse]]
  by (metis Domain_converse lvalueF lvalue_def)


definition "permutation_lvalue (p::'b\<Rightarrow>'a) a = {(inv p x, inv p y)| x y. (x,y) \<in> a}"

lemma permutation_lvalue_hom[simp]: "update_hom (permutation_lvalue p)"
  unfolding update_hom_def
  apply (rule exI[of _ \<open>{((x,y), (inv p x, inv p y))| x y. True}\<close>])
  by (auto simp: permutation_lvalue_def[abs_def])

lemma permutation_lvalue_lvalue: 
  fixes p :: "'b \<Rightarrow> 'a"
  assumes "bij p"
  shows "lvalue (permutation_lvalue p)"
proof (unfold lvalue_def, intro conjI allI)
  show \<open>update_hom (permutation_lvalue p)\<close>
    by simp
  show \<open>permutation_lvalue p Id = Id\<close>
    unfolding permutation_lvalue_def Id_def apply auto
    by (simp add: assms bij_inv_eq_iff)
  fix a a'
  show \<open>permutation_lvalue p a O permutation_lvalue p a' = permutation_lvalue p (a O a')\<close>
    apply (auto simp: permutation_lvalue_def relcomp_def relcompp_apply)
    by (metis assms bij_def surj_f_inv_f)
  show \<open>permutation_lvalue p (a\<inverse>) = (permutation_lvalue p a)\<inverse>\<close>
    by (auto simp: permutation_lvalue_def)
qed

lemma lvalue_prod1: \<open>lvalue (\<lambda>a. rel_prod a Id)\<close>
  unfolding lvalue_def apply (intro conjI allI)
  using update_2hom_left_is_hom tensor_update_is_2hom apply blast
    apply (simp add: tensor_update_mult)
   apply simp
  by (simp add: rel_prod_converse)


definition lvalue_from_setter :: \<open>('b\<Rightarrow>'a) \<Rightarrow> ('a\<Rightarrow>'b\<Rightarrow>'b) \<Rightarrow> ('a,'b) update_hom\<close> where
  \<open>lvalue_from_setter g s a = {(s ax b, s ay b) | b ax ay. (ax,ay) \<in> a}\<close>

lemma lvalue_from_setter_hom[simp]: "update_hom (lvalue_from_setter g s)"
  unfolding update_hom_def 
  apply (rule exI[of _ \<open>{((ax, ay), (s ax b, s ay b))| ax ay b. True}\<close>])
  apply (rule ext)
  by (auto simp: lvalue_from_setter_def[abs_def] Image_def[abs_def])

definition "valid_getter_setter g s \<longleftrightarrow> 
  (\<forall>b. b = s (g b) b) \<and> (\<forall>a b. g (s a b) = a) \<and> (\<forall>a a' b. s a (s a' b) = s a b)"

(* A bit stronger than lvalue_from_setter_lvalue *)
lemma lvalue_from_setter_lvalue': 
  fixes s :: "'a \<Rightarrow> 'b \<Rightarrow> 'b" and g :: "'b \<Rightarrow> 'a"
  assumes \<open>\<And>b. \<exists>b'. b = s (g b) b'\<close>
  assumes \<open>\<And>a b. g (s a b) = a\<close>
  assumes \<open>\<And>a a' b1 b2. s a b1 = s a b2 \<Longrightarrow> s a' b1 = s a' b2\<close>
  shows "lvalue (lvalue_from_setter g s)"
proof (unfold lvalue_def, intro conjI allI)
  show \<open>update_hom (lvalue_from_setter g s)\<close>
    by simp
  show \<open>lvalue_from_setter g s Id = Id\<close>
    unfolding lvalue_from_setter_def
    apply (auto simp: lvalue_from_setter_def)
    using assms by blast

  fix a 
  show \<open>lvalue_from_setter g s (a\<inverse>) = (lvalue_from_setter g s a)\<inverse>\<close>
    unfolding lvalue_from_setter_def
    by (auto simp: lvalue_from_setter_def)

  fix a'
  show \<open>lvalue_from_setter g s a O lvalue_from_setter g s a' = lvalue_from_setter g s (a O a')\<close>
    unfolding lvalue_from_setter_def
    apply (auto simp: lvalue_from_setter_def relcomp_def relcompp_apply)
    using assms
    by metis
qed


lemma lvalue_from_setter_lvalue[simp]:
  fixes s :: "'a \<Rightarrow> 'b \<Rightarrow> 'b" and g :: "'b \<Rightarrow> 'a"
  assumes "valid_getter_setter g s"
  shows "lvalue (lvalue_from_setter g s)"
  apply (rule lvalue_from_setter_lvalue'[where g=g])
  using assms unfolding valid_getter_setter_def by metis+

lemma lvalue_from_setter_set:
  assumes "valid_getter_setter g s"
  shows \<open>lvalue_from_setter g s {(a, a0)|a. True} = {(b, s a0 b)|b. True}\<close>
  using assms by (auto simp: valid_getter_setter_def lvalue_from_setter_def)

lemma lvalue_from_setter_map:
  assumes "valid_getter_setter g s"
  shows \<open>lvalue_from_setter g s {(a, f a)|a. True} = {(b, s (f (g b)) b)|b. True}\<close>
  using assms by (auto simp: valid_getter_setter_def lvalue_from_setter_def)


lemma lvalue_from_setter_compat:
  assumes [simp]: "valid_getter_setter g1 s1"
  assumes [simp]: "valid_getter_setter g2 s2"
  assumes \<open>\<And>a1 a2 b. s1 a1 (s2 a2 b) = s2 a2 (s1 a1 b)\<close>
  shows \<open>compatible (lvalue_from_setter g1 s1) (lvalue_from_setter g2 s2)\<close>
  unfolding compatible_def apply simp
  using assms unfolding valid_getter_setter_def
  apply (auto simp add: lvalue_from_setter_def relcomp_def relcompp_apply)
  by metis+


(* TODO: define setter_from_lvalue and to get the setter back. This 
         then implies that lvalues and getter/setters are the same. *)

subsubsection \<open>Example\<close>

record memory = 
  x :: "int*int"
  y :: nat

definition "X = lvalue_from_setter x (\<lambda>a b. b\<lparr>x:=a\<rparr>)"

lemma valid: \<open>valid_getter_setter x (\<lambda>a b. b\<lparr>x:=a\<rparr>)\<close>
  unfolding valid_getter_setter_def by auto

lemma lvalue: \<open>lvalue X\<close>
  by (simp add: valid X_def)


end
