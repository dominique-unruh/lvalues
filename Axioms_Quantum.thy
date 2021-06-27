section \<open>Quantum instantiation of registers\<close>

(* AXIOM INSTANTIATION (use instantiate_laws.py to generate Laws_Quantum.thy)

    # Type classes
    domain \<rightarrow> finite
    
    # Constants
    comp_update \<rightarrow> timesOp
    id_update \<rightarrow> idOp
    preregister \<rightarrow> clinear
    tensor_update \<rightarrow> tensor_op
    
    # Lemmas
    id_update_left \<rightarrow> times_idOp2
    id_update_right \<rightarrow> times_idOp1
    comp_update_assoc \<rightarrow> cblinfun_apply_assoc
    id_preregister \<rightarrow> complex_vector.linear_id
    comp_preregister \<rightarrow> clinear_compose
    tensor_update_mult \<rightarrow> comp_tensor_op
    # preregister_tensor_left \<rightarrow> clinear_tensor_right
    # preregister_tensor_right \<rightarrow> clinear_tensor_left

    # Chapter name
    Generic laws about registers \<rightarrow> Generic laws about registers, instantiated quantumly
    Generic laws about complements \<rightarrow> Generic laws about complements, instantiated quantumly
*)

theory Axioms_Quantum
  imports Jordan_Normal_Form.Matrix_Impl "HOL-Library.Rewrite"
          Bounded_Operators.Complex_L2
          Finite_Tensor_Product
begin


unbundle cblinfun_notation
no_notation m_inv ("inv\<index> _" [81] 80)

type_synonym 'a update = \<open>('a ell2, 'a ell2) cblinfun\<close>

lemma preregister_mult_right: \<open>clinear (\<lambda>a. a o\<^sub>C\<^sub>L z)\<close>
  by (simp add: cblinfun_apply_dist1 clinearI)
lemma preregister_mult_left: \<open>clinear (\<lambda>a. z o\<^sub>C\<^sub>L a)\<close>
  by (simp add: cblinfun_apply_dist2 clinearI)

definition register :: \<open>('a::finite update \<Rightarrow> 'b::finite update) \<Rightarrow> bool\<close> where
  "register F \<longleftrightarrow> 
     clinear F
   \<and> F idOp = idOp 
   \<and> (\<forall>a b. F(a o\<^sub>C\<^sub>L b) = F a o\<^sub>C\<^sub>L F b)
   \<and> (\<forall>a. F (a*) = (F a)*)"

lemma register_of_id: \<open>register F \<Longrightarrow> F idOp = idOp\<close>
  by (simp add: register_def)

lemma register_id: \<open>register id\<close>
  by (simp add: register_def complex_vector.module_hom_id)

lemma register_preregister: "register F \<Longrightarrow> clinear F"
  unfolding register_def by simp

lemma register_comp: "register F \<Longrightarrow> register G \<Longrightarrow> register (G \<circ> F)"
  unfolding register_def
  apply auto
  using clinear_compose by blast

lemma register_mult: "register F \<Longrightarrow> timesOp (F a) (F b) = F (timesOp a b)"
  unfolding register_def
  by auto

lemma register_tensor_left: \<open>register (\<lambda>a. tensor_op a idOp)\<close>
  by (simp add: comp_tensor_op register_def tensor_op_cbilinear tensor_op_adjoint)

lemma register_tensor_right: \<open>register (\<lambda>a. tensor_op idOp a)\<close>
  by (simp add: comp_tensor_op register_def tensor_op_cbilinear tensor_op_adjoint)


definition register_pair ::
  \<open>('a::finite update \<Rightarrow> 'c::finite update) \<Rightarrow> ('b::finite update \<Rightarrow> 'c update)
         \<Rightarrow> (('a\<times>'b) update \<Rightarrow> 'c update)\<close> where
  \<open>register_pair F G = tensor_lift (\<lambda>a b. F a o\<^sub>C\<^sub>L G b)\<close>

lemma cbilinear_F_comp_G[simp]: \<open>clinear F \<Longrightarrow> clinear G \<Longrightarrow> cbilinear (\<lambda>a b. F a o\<^sub>C\<^sub>L G b)\<close>
  unfolding cbilinear_def
  by (auto simp add: clinear_iff cblinfun_apply_dist1 cblinfun_apply_dist2)

lemma register_pair_apply: 
  assumes \<open>register F\<close> and \<open>register G\<close>
  assumes \<open>\<And>a b. F a o\<^sub>C\<^sub>L G b = G b o\<^sub>C\<^sub>L F a\<close>
  shows \<open>(register_pair F G) (tensor_op a b) = F a o\<^sub>C\<^sub>L G b\<close>
  unfolding register_pair_def
  apply (subst tensor_lift_correct[THEN fun_cong, THEN fun_cong])
  apply (rule cbilinear_F_comp_G)
  using assms apply (auto intro!: cbilinear_F_comp_G)
  using register_def by auto

lemma register_pair_is_register:
  fixes F :: \<open>'a::finite update \<Rightarrow> 'c::finite update\<close> and G
  assumes [simp]: \<open>register F\<close> and [simp]: \<open>register G\<close>
  assumes \<open>\<And>a b. F a o\<^sub>C\<^sub>L G b = G b o\<^sub>C\<^sub>L F a\<close>
  shows \<open>register (register_pair F G)\<close> 
proof (unfold register_def, intro conjI allI)
  have [simp]: \<open>clinear F\<close> \<open>clinear G\<close>
    using assms register_def by blast+
  have [simp]: \<open>F idOp = idOp\<close> \<open>G idOp = idOp\<close>
    using assms(1,2) register_def by blast+
  show [simp]: \<open>clinear (register_pair F G)\<close>
    unfolding register_pair_def apply (rule tensor_lift_clinear)
    by simp
  show \<open>register_pair F G idOp = idOp\<close>
    apply (simp flip: tensor_id)
    apply (subst register_pair_apply)
    using assms by simp_all
  have [simp]: \<open>clinear (\<lambda>y. register_pair F G (x o\<^sub>C\<^sub>L y))\<close> for x :: \<open>('a\<times>'b) update\<close>
    apply (rule clinear_compose[unfolded o_def, where g=\<open>register_pair F G\<close>])
    by (simp_all add: cblinfun_apply_dist2 clinearI)
  have [simp]: \<open>clinear (\<lambda>y. x o\<^sub>C\<^sub>L register_pair F G y)\<close> for x :: \<open>'c update\<close>
    apply (rule clinear_compose[unfolded o_def, where f=\<open>register_pair F G\<close>])
    by (simp_all add: cblinfun_apply_dist2 clinearI)
  have [simp]: \<open>clinear (\<lambda>x. register_pair F G (x o\<^sub>C\<^sub>L y))\<close> for y :: \<open>('a\<times>'b) update\<close>
    apply (rule clinear_compose[unfolded o_def, where g=\<open>register_pair F G\<close>])
    by (simp_all add: cblinfun_apply_dist1 clinearI)
  have [simp]: \<open>clinear (\<lambda>x. register_pair F G x o\<^sub>C\<^sub>L y)\<close> for y :: \<open>'c update\<close>
    apply (rule clinear_compose[unfolded o_def, where f=\<open>register_pair F G\<close>])
    by (simp_all add: cblinfun_apply_dist1 clinearI)
  have [simp]: \<open>F (x o\<^sub>C\<^sub>L y) = F x o\<^sub>C\<^sub>L F y\<close> for x y
    by (simp add: register_mult)
  have [simp]: \<open>G (x o\<^sub>C\<^sub>L y) = G x o\<^sub>C\<^sub>L G y\<close> for x y
    by (simp add: register_mult)
  have [simp]: \<open>clinear (\<lambda>a. (register_pair F G (a*))*)\<close>
    apply (rule antilinear_o_antilinear[unfolded o_def, where f=\<open>adj\<close>])
     apply (simp add: Adj_cblinfun_plus antilinearI)
    apply (rule antilinear_o_clinear[unfolded o_def, where g=\<open>adj\<close>])
    by (simp_all add: Adj_cblinfun_plus antilinearI)
  have [simp]: \<open>F (a*) = (F a)*\<close> for a
    using assms(1) register_def by blast
  have [simp]: \<open>G (b*) = (G b)*\<close> for b
    using assms(2) register_def by blast

  fix a b
  show \<open>register_pair F G (a o\<^sub>C\<^sub>L b) = register_pair F G a o\<^sub>C\<^sub>L register_pair F G b\<close>
    apply (rule tensor_extensionality[THEN fun_cong, where x=b], simp_all)
    apply (rule tensor_extensionality[THEN fun_cong, where x=a], simp_all)
    apply (simp_all add: comp_tensor_op register_pair_apply assms(3))
    using assms(3) by (metis assoc_left(1)) 
  have \<open>(register_pair F G (a*))* = register_pair F G a\<close>
    apply (rule tensor_extensionality[THEN fun_cong, where x=a])
    by (simp_all add: tensor_op_adjoint register_pair_apply assms(3))
  then show \<open>register_pair F G (a*) = register_pair F G a*\<close>
    by (metis adjoint_twice)
qed

end
