theory Finite_Tensor_Products
  imports Bounded_Operators.Complex_L2 Misc
begin

unbundle cblinfun_notation

lift_definition tensor_ell2 :: \<open>'a::finite ell2 \<Rightarrow> 'b::finite ell2 \<Rightarrow> ('a\<times>'b) ell2\<close> (infixr "\<otimes>\<^sub>s" 70) is
  \<open>\<lambda>\<psi> \<phi> (i,j). \<psi> i * \<phi> j\<close>
  by simp

lemma tensor_ell2_add2: \<open>tensor_ell2 a (b + c) = tensor_ell2 a b + tensor_ell2 a c\<close>
  apply transfer apply (rule ext) apply (auto simp: case_prod_beta)
  by (meson ordered_field_class.sign_simps(42))

lemma tensor_ell2_add1: \<open>tensor_ell2 (a + b) c = tensor_ell2 a c + tensor_ell2 b c\<close>
  apply transfer apply (rule ext) apply (auto simp: case_prod_beta)
  by (simp add: vector_space_over_itself.scale_left_distrib)

lemma tensor_ell2_scaleC2: \<open>tensor_ell2 a (c *\<^sub>C b) = c *\<^sub>C tensor_ell2 a b\<close>
  apply transfer apply (rule ext) by (auto simp: case_prod_beta)

lemma tensor_ell2_scaleC1: \<open>tensor_ell2 (c *\<^sub>C a) b = c *\<^sub>C tensor_ell2 a b\<close>
  apply transfer apply (rule ext) by (auto simp: case_prod_beta)

lemma tensor_ell2_inner_prod[simp]: \<open>\<langle>tensor_ell2 a b, tensor_ell2 c d\<rangle> = \<langle>a,c\<rangle> * \<langle>b,d\<rangle>\<close>
  apply transfer
  by (auto simp: case_prod_beta sum_product sum.cartesian_product mult.assoc mult.left_commute)

lemma clinear_tensor_ell21: "clinear (\<lambda>b. tensor_ell2 a b)"
  apply (rule clinearI; transfer)
  apply (auto simp: case_prod_beta)
  by (simp add: cond_case_prod_eta ordered_field_class.sign_simps(42))

lemma clinear_tensor_ell22: "clinear (\<lambda>a. tensor_ell2 a b)"
  apply (rule clinearI; transfer)
  apply (auto simp: case_prod_beta)
  by (simp add: case_prod_beta' mult.commute ordered_field_class.sign_simps(42))

lemma tensor_ell2_ket[simp]: "tensor_ell2 (ket i) (ket j) = ket (i,j)"
  apply transfer by auto


definition tensor_op :: \<open>('a ell2, 'b::finite ell2) cblinfun \<Rightarrow> ('c ell2, 'd::finite ell2) cblinfun
      \<Rightarrow> (('a\<times>'c) ell2, ('b\<times>'d) ell2) cblinfun\<close> where
  \<open>tensor_op M N = (SOME P. \<forall>a c. P *\<^sub>V (ket (a,c))
      = tensor_ell2 (M *\<^sub>V ket a) (N *\<^sub>V ket c))\<close>

lemma tensor_op_ket: 
  fixes a :: \<open>'a::finite\<close> and b :: \<open>'b\<close> and c :: \<open>'c::finite\<close> and d :: \<open>'d\<close>
  shows \<open>tensor_op M N *\<^sub>V (ket (a,c)) = tensor_ell2 (M *\<^sub>V ket a) (N *\<^sub>V ket c)\<close>
proof -
  define S :: \<open>('a\<times>'c) ell2 set\<close> where "S = ket ` UNIV"
  define \<phi> where \<open>\<phi> = (\<lambda>(a,c). tensor_ell2 (M *\<^sub>V ket a) (N *\<^sub>V ket c))\<close>
  define \<phi>' where \<open>\<phi>' = \<phi> \<circ> inv ket\<close>

  have def: \<open>tensor_op M N = (SOME P. \<forall>a c. P *\<^sub>V (ket (a,c)) = \<phi> (a,c))\<close>
    unfolding tensor_op_def \<phi>_def by auto

  have \<open>cindependent S\<close>
    using S_def cindependent_ket by blast
  moreover have \<open>cspan S = UNIV\<close>
    by (metis S_def finite_class.finite_UNIV finite_imageI ket_ell2_span span_finite_dim)
  moreover have \<open>finite S\<close>
    using S_def finite_class.finite_UNIV by blast
  ultimately have "cblinfun_extension_exists S \<phi>'"
    by (rule cblinfun_extension_exists_finite)
  then have "\<exists>P. \<forall>x\<in>S. P *\<^sub>V x = \<phi>' x"
    unfolding cblinfun_extension_exists_def by auto
  then have ex: \<open>\<exists>P. \<forall>a c. P *\<^sub>V ket (a,c) = \<phi> (a,c)\<close>
    by (metis S_def \<phi>'_def comp_eq_dest_lhs inj_ket inv_f_f rangeI)


  then have \<open>tensor_op M N *\<^sub>V (ket (a,c)) = \<phi> (a,c)\<close>
    unfolding def apply (rule someI2_ex[where P=\<open>\<lambda>P. \<forall>a c. P *\<^sub>V (ket (a,c)) = \<phi> (a,c)\<close>])
    by auto
  then show ?thesis
    unfolding \<phi>_def by auto
qed


lemma tensor_op_state: "tensor_op A B *\<^sub>V tensor_ell2 \<psi> \<phi> = tensor_ell2 (A *\<^sub>V \<psi>) (B *\<^sub>V \<phi>)"
proof -
  have 1: \<open>clinear (\<lambda>a. tensor_op A B *\<^sub>V tensor_ell2 a (ket b))\<close> for b
    by (auto intro!: clinearI simp: tensor_ell2_add1 tensor_ell2_scaleC1 cblinfun_apply_add)
  have 2: \<open>clinear (\<lambda>a. tensor_ell2 (A *\<^sub>V a) (B *\<^sub>V ket b))\<close> for b
    by (auto intro!: clinearI simp: tensor_ell2_add1 tensor_ell2_scaleC1 cblinfun_apply_add)
  have 3: \<open>clinear (\<lambda>a. tensor_op A B *\<^sub>V tensor_ell2 \<psi> a)\<close>
    by (auto intro!: clinearI simp: tensor_ell2_add2 tensor_ell2_scaleC2 cblinfun_apply_add)
  have 4: \<open>clinear (\<lambda>a. tensor_ell2 (A *\<^sub>V \<psi>) (B *\<^sub>V a))\<close>
    by (auto intro!: clinearI simp: tensor_ell2_add2 tensor_ell2_scaleC2 cblinfun_apply_add)

  have eq_ket_ket: \<open>tensor_op A B *\<^sub>V tensor_ell2 (ket a) (ket b) = tensor_ell2 (A *\<^sub>V ket a) (B *\<^sub>V ket b)\<close> for a b
    by (simp add: tensor_op_ket)
  have eq_ket: \<open>tensor_op A B *\<^sub>V tensor_ell2 \<psi> (ket b) = tensor_ell2 (A *\<^sub>V \<psi>) (B *\<^sub>V ket b)\<close> for b
    apply (rule fun_cong[where x=\<psi>])
    using 1 2 eq_ket_ket by (rule cbounded_linear_equal_ket)
  show ?thesis 
    apply (rule fun_cong[where x=\<phi>])
    using 3 4 eq_ket by (rule cbounded_linear_equal_ket)
qed

lemma comp_tensor_op: "(tensor_op a b) o\<^sub>C\<^sub>L (tensor_op c d) = tensor_op (a o\<^sub>C\<^sub>L c) (b o\<^sub>C\<^sub>L d)"
  for a :: "'e::finite ell2 \<Rightarrow>\<^sub>C\<^sub>L 'c::finite ell2" and b :: "'f::finite ell2 \<Rightarrow>\<^sub>C\<^sub>L 'd::finite ell2" and
  c :: "'a::finite ell2 \<Rightarrow>\<^sub>C\<^sub>L 'e ell2" and d :: "'b::finite ell2 \<Rightarrow>\<^sub>C\<^sub>L 'f ell2"
  apply (rule equal_ket)
  apply (rename_tac ij, case_tac ij, rename_tac i j, hypsubst_thin)
  by (simp flip: tensor_ell2_ket add: tensor_op_state times_applyOp)


lemma tensor_op_cbilinear: \<open>cbilinear (tensor_op :: 'a::finite ell2 \<Rightarrow>\<^sub>C\<^sub>L 'b::finite ell2
                                                 \<Rightarrow> 'c::finite ell2 \<Rightarrow>\<^sub>C\<^sub>L 'd::finite ell2 \<Rightarrow> _)\<close>
proof -
  have \<open>clinear (\<lambda>b::'c ell2 \<Rightarrow>\<^sub>C\<^sub>L 'd ell2. tensor_op a b)\<close> for a :: \<open>'a ell2 \<Rightarrow>\<^sub>C\<^sub>L 'b ell2\<close>
    apply (rule clinearI)
     apply (rule equal_ket, rename_tac ij, case_tac ij, rename_tac i j, hypsubst_thin)
     apply (simp flip: tensor_ell2_ket add: tensor_op_state apply_cblinfun_distr_left tensor_ell2_add2)
    apply (rule equal_ket, rename_tac ij, case_tac ij, rename_tac i j, hypsubst_thin)
    by (simp flip: tensor_ell2_ket add: tensor_op_state apply_cblinfun_distr_left tensor_ell2_scaleC2)

  moreover have \<open>clinear (\<lambda>a::'a::finite ell2 \<Rightarrow>\<^sub>C\<^sub>L 'b::finite ell2. tensor_op a b)\<close> for b :: \<open>'c ell2 \<Rightarrow>\<^sub>C\<^sub>L 'd ell2\<close>
    apply (rule clinearI)
     apply (rule equal_ket, rename_tac ij, case_tac ij, rename_tac i j, hypsubst_thin)
     apply (simp flip: tensor_ell2_ket add: tensor_op_state apply_cblinfun_distr_left tensor_ell2_add1)
    apply (rule equal_ket, rename_tac ij, case_tac ij, rename_tac i j, hypsubst_thin)
    by (simp flip: tensor_ell2_ket add: tensor_op_state apply_cblinfun_distr_left tensor_ell2_scaleC1)

  ultimately show ?thesis
    unfolding cbilinear_def by auto
qed


lemma tensor_butter: \<open>tensor_op (butterket i j) (butterket k l) = butterket (i,k) (j,l)\<close>
  for i :: "_" and j :: "_::finite" and k :: "_" and l :: "_::finite"
  apply (rule equal_ket, case_tac x)
  apply (auto simp flip: tensor_ell2_ket simp: times_applyOp tensor_op_state butterfly_def')
  by (auto simp: tensor_ell2_scaleC1 tensor_ell2_scaleC2)

lemma cspan_tensor_op: \<open>cspan {tensor_op (butterket i j) (butterket k l)| i (j::_::finite) k (l::_::finite). True} = UNIV\<close>
  unfolding tensor_butter
  apply (subst linfun_cspan[symmetric])
  by (metis surj_pair)

lemma cindependent_tensor_op: \<open>cindependent {tensor_op (butterket i j) (butterket k l)| i (j::_::finite) k (l::_::finite). True}\<close>
  unfolding tensor_butter
  using linfun_cindependent
  by (smt (z3) Collect_mono_iff complex_vector.independent_mono)


lemma tensor_extensionality:
  fixes F G :: \<open>((('a::finite \<times> 'b::finite) ell2) \<Rightarrow>\<^sub>C\<^sub>L (('c::finite \<times> 'd::finite) ell2)) \<Rightarrow> 'e::complex_vector\<close>
  assumes [simp]: "clinear F" "clinear G"
  assumes tensor_eq: "(\<And>a b. F (tensor_op a b) = G (tensor_op a b))"
  shows "F = G"
proof (rule ext, rule complex_vector.linear_eq_on_span[where f=F and g=G])
  show \<open>clinear F\<close> and \<open>clinear G\<close>
    using assms by (simp_all add: cbilinear_def)
  show \<open>x \<in> cspan  {tensor_op (butterket i j) (butterket k l)| i j k l. True}\<close> 
    for x :: \<open>('a \<times> 'b) ell2 \<Rightarrow>\<^sub>C\<^sub>L ('c \<times> 'd) ell2\<close>
    using cspan_tensor_op by auto
  show \<open>F x = G x\<close> if \<open>x \<in> {tensor_op (butterket i j) (butterket k l) |i j k l. True}\<close> for x
    using that by (auto simp: tensor_eq)
qed

lemma tensor_id[simp]: \<open>tensor_op idOp idOp = idOp\<close>
  apply (rule equal_ket, case_tac x)
  by (simp flip: tensor_ell2_ket add: tensor_op_state)

lemma tensor_op_adjoint: \<open>(tensor_op a b)* = tensor_op (a*) (b*)\<close>
  apply (rule cinner_ket_adjointI[symmetric])
  apply (auto simp flip: tensor_ell2_ket simp: tensor_op_state)
  by (simp add: adjoint_I)

lemma tensor_butterfly[simp]: "tensor_op (butterfly \<psi> \<psi>') (butterfly \<phi> \<phi>') = butterfly (tensor_ell2 \<psi> \<phi>) (tensor_ell2 \<psi>' \<phi>')"
  apply (rule equal_ket, case_tac x)
  by (simp flip: tensor_ell2_ket add: tensor_op_state butterfly_def'
      times_applyOp tensor_ell2_scaleC1 tensor_ell2_scaleC2)

end
