theory Teleport
  imports QHoare
    Real_Impl.Real_Impl "HOL-Library.Code_Target_Numeral"
begin

hide_const (open) Finite_Cartesian_Product.vec
hide_type (open) Finite_Cartesian_Product.vec
hide_const (open) Finite_Cartesian_Product.mat
hide_const (open) Finite_Cartesian_Product.row
hide_const (open) Finite_Cartesian_Product.column

no_notation mult (infixl "\<otimes>\<index>" 70)


term Inner_Product.real_inner_class.inner
unbundle no_vec_syntax
unbundle no_inner_syntax

declare lvalue_comp[simp] (* TODO: Laws *)

lemma [simp]: "dim_vec (vec_of_onb_enum (a :: 'a::enum ell2)) = CARD('a)"
  by (metis canonical_basis_length_ell2_def canonical_basis_length_eq dim_vec_of_onb_enum_list')

definition tensor_pack :: "nat \<Rightarrow> nat \<Rightarrow> (nat \<times> nat) \<Rightarrow> nat" where "tensor_pack X Y = (\<lambda>(x, y). x * Y + y)"
definition tensor_unpack :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> (nat \<times> nat)"  where "tensor_unpack X Y xy = (xy div Y, xy mod Y)"

lemma tensor_unpack_inj:
  assumes "i < A * B" and "j < A * B"
  shows "tensor_unpack A B i = tensor_unpack A B j \<longleftrightarrow> i = j"
  by (metis div_mult_mod_eq prod.sel(1) prod.sel(2) tensor_unpack_def)


lemma tensor_unpack_bound1[simp]: "i < A * B \<Longrightarrow> fst (tensor_unpack A B i) < A"
  unfolding tensor_unpack_def
  apply auto
  using less_mult_imp_div_less by blast
lemma tensor_unpack_bound2[simp]: "i < A * B \<Longrightarrow> snd (tensor_unpack A B i) < B"
  unfolding tensor_unpack_def
  apply auto
  by (metis mod_less_divisor mult.commute mult_zero_left nat_neq_iff not_less0)

lemma tensor_unpack_fstfst: \<open>fst (tensor_unpack A B (fst (tensor_unpack (A * B) C i)))
     = fst (tensor_unpack A (B * C) i)\<close>
  unfolding tensor_unpack_def apply auto
  by (metis div_mult2_eq mult.commute)
lemma tensor_unpack_sndsnd: \<open>snd (tensor_unpack B C (snd (tensor_unpack A (B * C) i)))
     = snd (tensor_unpack (A * B) C i)\<close>
  unfolding tensor_unpack_def apply auto
  by (meson dvd_triv_right mod_mod_cancel)
lemma tensor_unpack_fstsnd: \<open>fst (tensor_unpack B C (snd (tensor_unpack A (B * C) i)))
     = snd (tensor_unpack A B (fst (tensor_unpack (A * B) C i)))\<close>
  unfolding tensor_unpack_def apply auto
  by (metis (no_types, lifting) Euclidean_Division.div_eq_0_iff add_0_iff bits_mod_div_trivial div_mult_self4 mod_mult2_eq mod_mult_self1_is_0 mult.commute)


definition "tensor_state_jnf \<psi> \<phi> = (let d1 = dim_vec \<psi> in let d2 = dim_vec \<phi> in
  vec (d1*d2) (\<lambda>i. let (i1,i2) = tensor_unpack d1 d2 i in (vec_index \<psi> i1) * (vec_index \<phi> i2)))"

lemma tensor_state_jnf_dim[simp]: \<open>dim_vec (tensor_state_jnf \<psi> \<phi>) = dim_vec \<psi> * dim_vec \<phi>\<close>
  unfolding tensor_state_jnf_def Let_def by simp

lemma index_of_nth:
  assumes "distinct xs"
  assumes "i < length xs"
  shows "index_of (xs ! i) xs = i"
  using assms
  by (metis distinct_conv_nth index_of_bound index_of_correct length_nth_simps(1) not_less_zero nth_mem)


lemma enum_idx_enum: 
  assumes \<open>i < CARD('a::enum)\<close>
  shows \<open>enum_idx (enum_class.enum ! i :: 'a) = i\<close>
  unfolding enum_idx_def apply (rule index_of_nth)
  using assms by (simp_all add: card_UNIV_length_enum enum_distinct)

lemma cinner_ket: \<open>\<langle>ket i, \<psi>\<rangle> = Rep_ell2 \<psi> i\<close>
  apply (transfer fixing: i)
  apply (subst infsetsum_cong_neutral[where B=\<open>{i}\<close>])
  by auto

lemma vec_of_onb_enum_ell2_index:
  fixes \<psi> :: \<open>'a::enum ell2\<close> 
  assumes [simp]: \<open>i < CARD('a)\<close>
  shows \<open>vec_of_onb_enum \<psi> $ i = Rep_ell2 \<psi> (Enum.enum ! i)\<close>
proof -
  let ?i = \<open>Enum.enum ! i\<close>
  have \<open>Rep_ell2 \<psi> (Enum.enum ! i) = \<langle>ket ?i, \<psi>\<rangle>\<close>
    by (simp add: cinner_ket)
  also have \<open>\<dots> = vec_of_onb_enum \<psi> \<bullet>c vec_of_onb_enum (ket ?i :: 'a ell2)\<close>
    by (rule cscalar_prod_cinner)
  also have \<open>\<dots> = vec_of_onb_enum \<psi> \<bullet>c unit_vec (CARD('a)) i\<close>
    by (simp add: vec_of_onb_enum_ket enum_idx_enum canonical_basis_length_ell2_def)
  also have \<open>\<dots> = vec_of_onb_enum \<psi> \<bullet> unit_vec (CARD('a)) i\<close>
    by (smt (verit, best) assms carrier_vecI conjugate_conjugate_sprod conjugate_id conjugate_vec_sprod_comm dim_vec_conjugate eq_vecI index_unit_vec(3) scalar_prod_left_unit vec_index_conjugate)
  also have \<open>\<dots> = vec_of_onb_enum \<psi> $ i\<close>
    by simp
  finally show ?thesis
    by simp
qed

lemma enum_prod_nth_tensor_unpack:
  assumes \<open>i < CARD('a) * CARD('b)\<close>
  shows "(Enum.enum ! i :: 'a::enum\<times>'b::enum) = 
        (let (i1,i2) = tensor_unpack CARD('a) CARD('b) i in 
              (Enum.enum ! i1, Enum.enum ! i2))"
  using assms 
  by (simp add: enum_prod_def card_UNIV_length_enum product_nth tensor_unpack_def)

lemma vec_of_onb_enum_tensor_state_index:
  fixes \<psi> :: \<open>'a::enum ell2\<close> and \<phi> :: \<open>'b::enum ell2\<close>
  assumes [simp]: \<open>i < CARD('a) * CARD('b)\<close>
  shows \<open>vec_of_onb_enum (\<psi> \<otimes>\<^sub>s \<phi>) $ i = (let (i1,i2) = tensor_unpack CARD('a) CARD('b) i in
    vec_of_onb_enum \<psi> $ i1 * vec_of_onb_enum \<phi> $ i2)\<close>
proof -
  define i1 i2 where "i1 = fst (tensor_unpack CARD('a) CARD('b) i)"
    and "i2 = snd (tensor_unpack CARD('a) CARD('b) i)"
  have [simp]: "i1 < CARD('a)" "i2 < CARD('b)"
    using assms i1_def tensor_unpack_bound1 apply presburger
    using assms i2_def tensor_unpack_bound2 by presburger

  have \<open>vec_of_onb_enum (\<psi> \<otimes>\<^sub>s \<phi>) $ i = Rep_ell2 (\<psi> \<otimes>\<^sub>s \<phi>) (enum_class.enum ! i)\<close>
    by (simp add: vec_of_onb_enum_ell2_index)
  also have \<open>\<dots> = Rep_ell2 \<psi> (Enum.enum!i1) * Rep_ell2 \<phi> (Enum.enum!i2)\<close>
    apply (transfer fixing: i i1 i2)
    by (simp add: enum_prod_nth_tensor_unpack case_prod_beta i1_def i2_def)
  also have \<open>\<dots> = vec_of_onb_enum \<psi> $ i1 * vec_of_onb_enum \<phi> $ i2\<close>
    by (simp add: vec_of_onb_enum_ell2_index)
  finally show ?thesis
    by (simp add: case_prod_beta i1_def i2_def)
qed

lemma vec_of_onb_enum_tensor_state:
  fixes \<psi> :: \<open>'a::enum ell2\<close> and \<phi> :: \<open>'b::enum ell2\<close>
  shows \<open>vec_of_onb_enum (\<psi> \<otimes>\<^sub>s \<phi>) = tensor_state_jnf (vec_of_onb_enum \<psi>) (vec_of_onb_enum \<phi>)\<close>
  apply (rule eq_vecI, simp_all)
  apply (subst vec_of_onb_enum_tensor_state_index, simp_all)
  by (simp add: tensor_state_jnf_def case_prod_beta Let_def)

lemma [simp]: \<open>mat_of_cblinfun (a::'a::enum ell2 \<Rightarrow>\<^sub>C\<^sub>L 'b::enum ell2) \<in> carrier_mat CARD('b) CARD('a)\<close>
  by (simp add: canonical_basis_length_ell2_def mat_of_cblinfun_def)
  


lemma mat_of_cblinfun_ell2_index:
  fixes a :: \<open>'a::enum ell2 \<Rightarrow>\<^sub>C\<^sub>L 'b::enum ell2\<close> 
  assumes [simp]: \<open>i < CARD('b)\<close> \<open>j < CARD('a)\<close>
  shows \<open>mat_of_cblinfun a $$ (i,j) = Rep_ell2 (a *\<^sub>V ket (Enum.enum ! j)) (Enum.enum ! i)\<close>
proof -
  let ?i = \<open>Enum.enum ! i\<close> and ?j = \<open>Enum.enum ! j\<close> and ?aj = \<open>a *\<^sub>V ket (Enum.enum ! j)\<close>
  have \<open>Rep_ell2 ?aj (Enum.enum ! i) = vec_of_onb_enum ?aj $ i\<close>
    by (rule vec_of_onb_enum_ell2_index[symmetric], simp)
  also have \<open>\<dots> = (mat_of_cblinfun a *\<^sub>v vec_of_onb_enum (ket (enum_class.enum ! j) :: 'a ell2)) $ i\<close>
    by (simp add: mat_of_cblinfun_description)
  also have \<open>\<dots> = (mat_of_cblinfun a *\<^sub>v unit_vec CARD('a) j) $ i\<close>
    by (simp add: vec_of_onb_enum_ket enum_idx_enum canonical_basis_length_ell2_def)
  also have \<open>\<dots> = mat_of_cblinfun a $$ (i, j)\<close>
    apply (subst mat_entry_explicit[where m=\<open>CARD('b)\<close>])
    by auto
  finally show ?thesis
    by auto
qed


lemma dim_row_mat_of_cblinfun[simp]:
  \<open>dim_row (mat_of_cblinfun (a :: 'a::onb_enum\<Rightarrow>\<^sub>C\<^sub>L'b::onb_enum)) = canonical_basis_length TYPE('b)\<close>
  unfolding mat_of_cblinfun_def by auto

lemma dim_col_mat_of_cblinfun[simp]:
  \<open>dim_col (mat_of_cblinfun (a :: 'a::onb_enum\<Rightarrow>\<^sub>C\<^sub>L'b::onb_enum)) = canonical_basis_length TYPE('a)\<close>
  unfolding mat_of_cblinfun_def by auto

lemma mat_of_cblinfun_tensor_op_index:
  fixes a :: \<open>'a::enum ell2 \<Rightarrow>\<^sub>C\<^sub>L 'b::enum ell2\<close> and b :: \<open>'c::enum ell2 \<Rightarrow>\<^sub>C\<^sub>L 'd::enum ell2\<close>
  assumes [simp]: \<open>i < CARD('b) * CARD('d)\<close>
  assumes [simp]: \<open>j < CARD('a) * CARD('c)\<close>
  shows \<open>mat_of_cblinfun (tensor_op a b) $$ (i,j) = 
            (let (i1,i2) = tensor_unpack CARD('b) CARD('d) i in
             let (j1,j2) = tensor_unpack CARD('a) CARD('c) j in
                  mat_of_cblinfun a $$ (i1,j1) * mat_of_cblinfun b $$ (i2,j2))\<close>
proof -
  define i1 i2 j1 j2
    where "i1 = fst (tensor_unpack CARD('b) CARD('d) i)"
      and "i2 = snd (tensor_unpack CARD('b) CARD('d) i)"
      and "j1 = fst (tensor_unpack CARD('a) CARD('c) j)"
      and "j2 = snd (tensor_unpack CARD('a) CARD('c) j)"
  have [simp]: "i1 < CARD('b)" "i2 < CARD('d)" "j1 < CARD('a)" "j2 < CARD('c)"
    using assms i1_def tensor_unpack_bound1 apply presburger
    using assms i2_def tensor_unpack_bound2 apply blast
    using assms(2) j1_def tensor_unpack_bound1 apply blast
    using assms(2) j2_def tensor_unpack_bound2 by presburger

  have \<open>mat_of_cblinfun (tensor_op a b) $$ (i,j) 
       = Rep_ell2 (tensor_op a b *\<^sub>V ket (Enum.enum!j)) (Enum.enum ! i)\<close>
    by (simp add: mat_of_cblinfun_ell2_index)
  also have \<open>\<dots> = Rep_ell2 ((a *\<^sub>V ket (Enum.enum!j1)) \<otimes>\<^sub>s (b *\<^sub>V ket (Enum.enum!j2))) (Enum.enum!i)\<close>
    by (simp add: tensor_op_ell2 enum_prod_nth_tensor_unpack[where i=j] Let_def case_prod_beta j1_def[symmetric] j2_def[symmetric] flip: tensor_ell2_ket)
  also have \<open>\<dots> = vec_of_onb_enum ((a *\<^sub>V ket (Enum.enum!j1)) \<otimes>\<^sub>s b *\<^sub>V ket (Enum.enum!j2)) $ i\<close>
    by (simp add: vec_of_onb_enum_ell2_index)
  also have \<open>\<dots> = vec_of_onb_enum (a *\<^sub>V ket (enum_class.enum ! j1)) $ i1 *
                  vec_of_onb_enum (b *\<^sub>V ket (enum_class.enum ! j2)) $ i2\<close>
    by (simp add: case_prod_beta vec_of_onb_enum_tensor_state_index i1_def[symmetric] i2_def[symmetric])
  also have \<open>\<dots> = Rep_ell2 (a *\<^sub>V ket (enum_class.enum ! j1)) (enum_class.enum ! i1) *
                  Rep_ell2 (b *\<^sub>V ket (enum_class.enum ! j2)) (enum_class.enum ! i2)\<close>
    by (simp add: vec_of_onb_enum_ell2_index)
  also have \<open>\<dots> = mat_of_cblinfun a $$ (i1, j1) * mat_of_cblinfun b $$ (i2, j2)\<close>
    by (simp add: mat_of_cblinfun_ell2_index)
  finally show ?thesis
    by (simp add: i1_def[symmetric] i2_def[symmetric] j1_def[symmetric] j2_def[symmetric] case_prod_beta)
qed


definition "tensor_op_jnf A B = 
  (let r1 = dim_row A in
   let c1 = dim_col A in
   let r2 = dim_row B in
   let c2 = dim_col B in
   mat (r1*r2) (c1*c2)
   (\<lambda>(i,j). let (i1,i2) = tensor_unpack r1 r2 i in
            let (j1,j2) = tensor_unpack c1 c2 j in
              (A $$ (i1,j1)) * (B $$ (i2,j2))))"

lemma tensor_op_jnf_dim[simp]: 
  \<open>dim_row (tensor_op_jnf a b) = dim_row a * dim_row b\<close>
  \<open>dim_col (tensor_op_jnf a b) = dim_col a * dim_col b\<close>
  unfolding tensor_op_jnf_def Let_def by simp_all


lemma mat_of_cblinfun_tensor_op:
  fixes a :: \<open>'a::enum ell2 \<Rightarrow>\<^sub>C\<^sub>L 'b::enum ell2\<close> and b :: \<open>'c::enum ell2 \<Rightarrow>\<^sub>C\<^sub>L 'd::enum ell2\<close>
  shows \<open>mat_of_cblinfun (tensor_op a b) = tensor_op_jnf (mat_of_cblinfun a) (mat_of_cblinfun b)\<close>
  apply (rule eq_matI, simp_all add: canonical_basis_length_ell2_def)
  apply (subst mat_of_cblinfun_tensor_op_index, simp_all)
  by (simp add: tensor_op_jnf_def case_prod_beta Let_def canonical_basis_length_ell2_def)

locale teleport_locale = qhoare "TYPE('mem::finite)" +
  fixes X :: "(bit,'mem::finite) maps_hom"
    and \<Phi> :: "(bit*bit,'mem) maps_hom"
    and A :: "('atype::finite,'mem) maps_hom"
    and B :: "('btype::finite,'mem) maps_hom"
  assumes compat[compatible]: "mutually compatible (X,\<Phi>,A,B)"
begin

abbreviation "\<Phi>1 \<equiv> \<Phi> \<circ> Fst"
abbreviation "\<Phi>2 \<equiv> \<Phi> \<circ> Snd"
abbreviation "X\<Phi>2 \<equiv> pair X \<Phi>2"
abbreviation "X\<Phi>1 \<equiv> pair X \<Phi>1"
abbreviation "X\<Phi> \<equiv> pair X \<Phi>"
abbreviation "XAB \<equiv> pair (pair X A) B"
abbreviation "AB \<equiv> pair A B"
abbreviation "\<Phi>2AB \<equiv> pair (pair (\<Phi> o Snd) A) B"

definition "teleport a b = [
    apply CNOT X\<Phi>1,
    apply hadamard X,
    ifthen \<Phi>1 a,
    ifthen X b, 
    apply (if a=1 then pauliX else idOp) \<Phi>2,
    apply (if b=1 then pauliZ else idOp) \<Phi>2
  ]"

definition "teleport_pre \<psi> = EQ XAB \<psi> \<sqinter> EQ \<Phi> \<beta>00"
definition "teleport_post \<psi> = EQ \<Phi>2AB \<psi>"

lemma tensor_ell2_extensionality:
  assumes "(\<And>s t. a *\<^sub>V (s \<otimes>\<^sub>s t) = b *\<^sub>V (s \<otimes>\<^sub>s t))"
  shows "a = b"
  apply (rule equal_ket, case_tac x, hypsubst_thin)
  by (simp add: assms flip: tensor_ell2_ket)


lemma cblinfun_eq_mat_of_cblinfunI: 
  assumes "mat_of_cblinfun a = mat_of_cblinfun b"
  shows "a = b"
  by (metis assms mat_of_cblinfun_inverse)

lemma ell2_eq_vec_of_onb_enumI: 
  fixes a b :: "_::onb_enum"
  assumes "vec_of_onb_enum a = vec_of_onb_enum b"
  shows "a = b"
  by (metis assms onb_enum_of_vec_inverse)

lemma Uswap_apply[simp]: \<open>Uswap *\<^sub>V s \<otimes>\<^sub>s t = t \<otimes>\<^sub>s s\<close>
  apply (rule cbounded_linear_equal_ket[where f=\<open>\<lambda>s. Uswap *\<^sub>V s \<otimes>\<^sub>s t\<close>, THEN fun_cong])
  apply (simp add: cblinfun_apply_add clinearI tensor_ell2_add1 tensor_ell2_scaleC1)
  apply (simp add: clinear_tensor_ell21)
  apply (rule cbounded_linear_equal_ket[where f=\<open>\<lambda>t. Uswap *\<^sub>V _ \<otimes>\<^sub>s t\<close>, THEN fun_cong])
  apply (simp add: cblinfun_apply_add clinearI tensor_ell2_add2 tensor_ell2_scaleC2)
  apply (simp add: clinear_tensor_ell22)
  apply (rule ell2_eq_vec_of_onb_enumI)
  apply (simp add: mat_of_cblinfun_description vec_of_onb_enum_ket
      canonical_basis_length_ell2_def)
  by (case_tac i; case_tac ia; hypsubst_thin; normalization)

lemma swap_sandwich: "swap a = Uswap o\<^sub>C\<^sub>L a o\<^sub>C\<^sub>L Uswap"
  apply (rule fun_cong[where x=a])
  apply (rule tensor_extensionality)
  apply auto
  using comp_2hom maps_2hom_hom_comp1 maps_2hom_left maps_2hom_right apply blast
  apply (rule tensor_ell2_extensionality)
  by (simp add: times_applyOp tensor_op_ell2)

lemma enum_inj:
  assumes "i < CARD('a)" and "j < CARD('a)"
  shows "(Enum.enum ! i :: 'a::enum) = Enum.enum ! j \<longleftrightarrow> i = j"
  using inj_on_nth[OF enum_distinct, where I=\<open>{..<CARD('a)}\<close>]
  using assms by (auto dest: inj_onD simp flip: card_UNIV_length_enum)


lemma mat_of_cblinfun_assoc_ell2'[simp]: 
  \<open>mat_of_cblinfun (assoc_ell2' :: (('a::enum\<times>('b::enum\<times>'c::enum)) ell2 \<Rightarrow>\<^sub>C\<^sub>L _)) = one_mat (CARD('a)*CARD('b)*CARD('c))\<close>
  (is "mat_of_cblinfun ?assoc = _")
proof  (rule mat_eq_iff[THEN iffD2], intro conjI allI impI)

  show \<open>dim_row (mat_of_cblinfun ?assoc) =
    dim_row (1\<^sub>m (CARD('a) * CARD('b) * CARD('c)))\<close>
    by (simp add: canonical_basis_length_ell2_def)
  show \<open>dim_col (mat_of_cblinfun ?assoc) =
    dim_col (1\<^sub>m (CARD('a) * CARD('b) * CARD('c)))\<close>
    by (simp add: canonical_basis_length_ell2_def)

  fix i j
  let ?i = "Enum.enum ! i :: (('a\<times>'b)\<times>'c)" and ?j = "Enum.enum ! j :: ('a\<times>('b\<times>'c))"

  assume \<open>i < dim_row (1\<^sub>m (CARD('a) * CARD('b) * CARD('c)))\<close>
  then have iB[simp]: \<open>i < CARD('a) * CARD('b) * CARD('c)\<close> by simp
  then have iB'[simp]: \<open>i < CARD('a) * (CARD('b) * CARD('c))\<close> by linarith
  assume \<open>j < dim_col (1\<^sub>m (CARD('a) * CARD('b) * CARD('c)))\<close>
  then have jB[simp]: \<open>j < CARD('a) * CARD('b) * CARD('c)\<close> by simp
  then have jB'[simp]: \<open>j < CARD('a) * (CARD('b) * CARD('c))\<close> by linarith

  define i1 i23 i2 i3
    where "i1 = fst (tensor_unpack CARD('a) (CARD('b)*CARD('c)) i)"
      and "i23 = snd (tensor_unpack CARD('a) (CARD('b)*CARD('c)) i)"
      and "i2 = fst (tensor_unpack CARD('b) CARD('c) i23)"
      and "i3 = snd (tensor_unpack CARD('b) CARD('c) i23)"
  define j12 j1 j2 j3
    where "j12 = fst (tensor_unpack (CARD('a)*CARD('b)) CARD('c) j)"
      and "j1 = fst (tensor_unpack CARD('a) CARD('b) j12)"
      and "j2 = snd (tensor_unpack CARD('a) CARD('b) j12)"
      and "j3 = snd (tensor_unpack (CARD('a)*CARD('b)) CARD('c) j)"

  have [simp]: "j12 < CARD('a)*CARD('b)" "i23 < CARD('b)*CARD('c)"
    using j12_def jB tensor_unpack_bound1 apply presburger
    using i23_def iB' tensor_unpack_bound2 by blast

  have j1': \<open>fst (tensor_unpack CARD('a) (CARD('b) * CARD('c)) j) = j1\<close>
    by (simp add: j1_def j12_def tensor_unpack_fstfst)

  let ?i1 = "Enum.enum ! i1 :: 'a" and ?i2 = "Enum.enum ! i2 :: 'b" and ?i3 = "Enum.enum ! i3 :: 'c"
  let ?j1 = "Enum.enum ! j1 :: 'a" and ?j2 = "Enum.enum ! j2 :: 'b" and ?j3 = "Enum.enum ! j3 :: 'c"

  have i: \<open>?i = ((?i1,?i2),?i3)\<close>
    by (auto simp add: enum_prod_nth_tensor_unpack case_prod_beta
          tensor_unpack_fstfst tensor_unpack_fstsnd tensor_unpack_sndsnd i1_def i2_def i23_def i3_def)
  have j: \<open>?j = (?j1,(?j2,?j3))\<close> 
    by (auto simp add: enum_prod_nth_tensor_unpack case_prod_beta
        tensor_unpack_fstfst tensor_unpack_fstsnd tensor_unpack_sndsnd j1_def j2_def j12_def j3_def)
  have ijeq: \<open>(?i1,?i2,?i3) = (?j1,?j2,?j3) \<longleftrightarrow> i = j\<close>
    unfolding i1_def i2_def i3_def j1_def j2_def j3_def apply simp
    apply (subst enum_inj, simp, simp)
    apply (subst enum_inj, simp, simp)
    apply (subst enum_inj, simp, simp)
    apply (subst tensor_unpack_inj[symmetric, where i=i and j=j and A="CARD('a)" and B="CARD('b)*CARD('c)"], simp, simp)
    unfolding prod_eq_iff
    apply (subst tensor_unpack_inj[symmetric, where i=\<open>snd (tensor_unpack CARD('a) (CARD('b) * CARD('c)) i)\<close> and A="CARD('b)" and B="CARD('c)"], simp, simp)
    by (simp add: i1_def[symmetric] j1_def[symmetric] i2_def[symmetric] j2_def[symmetric] i3_def[symmetric] j3_def[symmetric]
        i23_def[symmetric] j12_def[symmetric] j1'
        prod_eq_iff tensor_unpack_fstsnd tensor_unpack_sndsnd)

  have \<open>mat_of_cblinfun ?assoc $$ (i, j) = Rep_ell2 (assoc_ell2' *\<^sub>V ket ?j) ?i\<close>
    by (subst mat_of_cblinfun_ell2_index, auto)
  also have \<open>\<dots> = Rep_ell2 ((ket ?j1 \<otimes>\<^sub>s ket ?j2) \<otimes>\<^sub>s ket ?j3) ?i\<close>
    by (simp add: j assoc_ell2'_tensor flip: tensor_ell2_ket)
  also have \<open>\<dots> = (if (?i1,?i2,?i3) = (?j1,?j2,?j3) then 1 else 0)\<close>
    by (auto simp add: ket.rep_eq i)
  also have \<open>\<dots> = (if i=j then 1 else 0)\<close>
    using ijeq by simp
  finally
  show \<open>mat_of_cblinfun ?assoc $$ (i, j) =
           1\<^sub>m (CARD('a) * CARD('b) * CARD('c)) $$ (i, j)\<close>
    by auto
qed

lemma assoc_ell2'_inv: "assoc_ell2 o\<^sub>C\<^sub>L assoc_ell2' = idOp"
  apply (rule equal_ket, case_tac x, hypsubst)
  by (simp flip: tensor_ell2_ket add: times_applyOp assoc_ell2'_tensor assoc_ell2_tensor)

lemma assoc_ell2_inv: "assoc_ell2' o\<^sub>C\<^sub>L assoc_ell2 = idOp"
  apply (rule equal_ket, case_tac x, case_tac a, hypsubst)
  by (simp flip: tensor_ell2_ket add: times_applyOp assoc_ell2'_tensor assoc_ell2_tensor)

lemma mat_of_cblinfun_assoc_ell2[simp]: 
  \<open>mat_of_cblinfun (assoc_ell2 :: ((('a::enum\<times>'b::enum)\<times>'c::enum) ell2 \<Rightarrow>\<^sub>C\<^sub>L _)) = one_mat (CARD('a)*CARD('b)*CARD('c))\<close>
  (is "mat_of_cblinfun ?assoc = _")
proof -
  let ?assoc' = "assoc_ell2' :: (('a::enum\<times>('b::enum\<times>'c::enum)) ell2 \<Rightarrow>\<^sub>C\<^sub>L _)"
  have "one_mat (CARD('a)*CARD('b)*CARD('c)) = mat_of_cblinfun (?assoc o\<^sub>C\<^sub>L ?assoc')"
    by (simp add: mult.assoc assoc_ell2'_inv cblinfun_of_mat_id canonical_basis_length_ell2_def)
  also have \<open>\<dots> = mat_of_cblinfun ?assoc * mat_of_cblinfun ?assoc'\<close>
    using cblinfun_of_mat_timesOp by blast
  also have \<open>\<dots> = mat_of_cblinfun ?assoc * one_mat (CARD('a)*CARD('b)*CARD('c))\<close>
    by simp
  also have \<open>\<dots> = mat_of_cblinfun ?assoc\<close>
    apply (rule right_mult_one_mat')
    by (simp add: canonical_basis_length_ell2_def)
  finally show ?thesis
    by simp
qed


lemma [simp]: "dim_col (mat_adjoint m) = dim_row m"
  unfolding mat_adjoint_def by simp
lemma [simp]: "dim_row (mat_adjoint m) = dim_col m"
  unfolding mat_adjoint_def by simp

term tensor_maps_hom
lemma
 tensor_maps_hom_sandwich2: 
  fixes a :: "'a::finite ell2 \<Rightarrow>\<^sub>C\<^sub>L 'b::finite ell2" and b :: "'b::finite ell2 \<Rightarrow>\<^sub>C\<^sub>L 'a::finite ell2"
  shows "id \<otimes>\<^sub>h (\<lambda>x. b o\<^sub>C\<^sub>L x o\<^sub>C\<^sub>L a)
             = (\<lambda>x. (tensor_op idOp b) o\<^sub>C\<^sub>L x o\<^sub>C\<^sub>L (tensor_op idOp a))"
proof -
  have [simp]: \<open>clinear (id \<otimes>\<^sub>h (\<lambda>x. b o\<^sub>C\<^sub>L x o\<^sub>C\<^sub>L a))\<close>
    by (auto intro!:  clinearI tensor_maps_hom_hom simp add: cblinfun_apply_dist1 cblinfun_apply_dist2)
  have [simp]: \<open>clinear (\<lambda>x. tensor_op idOp b o\<^sub>C\<^sub>L x o\<^sub>C\<^sub>L tensor_op idOp a)\<close>
    by (simp add: cblinfun_apply_dist1 cblinfun_apply_dist2 clinearI)
  have [simp]: \<open>clinear (\<lambda>x. b o\<^sub>C\<^sub>L x o\<^sub>C\<^sub>L a)\<close>
    by (simp add: cblinfun_apply_dist1 cblinfun_apply_dist2 clinearI)
  show ?thesis
    apply (rule tensor_extensionality, simp, simp)
    apply (subst tensor_maps_hom_apply, simp, simp)
    by (simp add: comp_tensor_op)
qed

lemma clinear_Fst[simp]: "clinear Fst"
  unfolding Fst_def by auto
lemma clinear_Snd[simp]: "clinear Snd"
  unfolding Fst_def by auto

lemma [compatible]: "mutually compatible (Fst, Snd)"
  using [[simproc del: compatibility_warn]]
  by (auto intro!: compatibleI simp add: Fst_def Snd_def comp_tensor_op)

(* TODO: Can we formulate this in Laws? Can Fst/Snd be formulated generically? *)
lemma pair_Fst_Snd[simp]: 
  assumes \<open>lvalue F\<close>
  shows \<open>pair (F o Fst) (F o Snd) = F\<close>
  apply (rule tensor_extensionality)
  using assms by (auto simp: pair_apply Fst_def Snd_def lvalue_mult comp_tensor_op)

(* TODO: get rid of "Simplification subgoal compatible (F \<circ> Fst) F" warning *)

lemma \<Phi>_X\<Phi>: \<open>\<Phi> a = X\<Phi> (idOp \<otimes> a)\<close>
  by (auto simp: pair_apply)
lemma X\<Phi>1_X\<Phi>: \<open>X\<Phi>1 a = X\<Phi> (assoc (a \<otimes> idOp))\<close>
  apply (subst pair_comp_assoc[unfolded o_def, of X \<Phi>1 \<Phi>2, simplified, THEN fun_cong])
  by (auto simp: pair_apply)
lemma X\<Phi>2_X\<Phi>: \<open>X\<Phi>2 a = X\<Phi> ((id \<otimes>\<^sub>h swap) (assoc (a \<otimes> idOp)))\<close>
  apply (subst pair_comp_tensor[unfolded o_def, THEN fun_cong], simp, simp, simp)
  apply (subst (2) pair_Fst_Snd[symmetric, of \<Phi>], simp)
  apply (subst pair_comp_swap', simp)
  apply (subst pair_comp_assoc[unfolded o_def, THEN fun_cong], simp, simp, simp)
  by (auto simp: pair_apply)
lemma \<Phi>2_X\<Phi>: \<open>\<Phi>2 a = X\<Phi> (idOp \<otimes> (idOp \<otimes> a))\<close>
  by (auto simp: Snd_def pair_apply)
lemmas to_X\<Phi> = \<Phi>_X\<Phi> X\<Phi>1_X\<Phi> X\<Phi>2_X\<Phi> \<Phi>2_X\<Phi>

lemma X_X\<Phi>1: \<open>X a = X\<Phi>1 (a \<otimes> idOp)\<close>
  by (auto simp: pair_apply)
lemmas to_X\<Phi>1 = X_X\<Phi>1

lemma X\<Phi>1_X\<Phi>1_AB: \<open>X\<Phi>1 a = (X\<Phi>1;AB) (a \<otimes> idOp)\<close>
  by (auto simp: pair_apply)
lemma XAB_X\<Phi>1_AB: \<open>XAB a = (X\<Phi>1;AB) (((\<lambda>x. x \<otimes> idOp) \<otimes>\<^sub>h id) (assoc a))\<close>
  apply (rule tensor_extensionality[THEN fun_cong, where x=a])
    apply simp
  subgoal sorry
  subgoal for a b
  apply (rule tensor_extensionality[THEN fun_cong, where x=a])
  subgoal sorry
  subgoal sorry
  sorry sorry
lemmas to_X\<Phi>1_AB = X\<Phi>1_X\<Phi>1_AB XAB_X\<Phi>1_AB

lemma butterfly_times_right: "butterfly \<psi> \<phi> o\<^sub>C\<^sub>L a = butterfly \<psi> (a* *\<^sub>V \<phi>)"
  unfolding butterfly_def'
  by (simp add: cblinfun_apply_assoc vector_to_cblinfun_applyOp)  


lemma swap_lvalues_applySpace:
  assumes "compatible R S"
  shows "R a *\<^sub>S S b *\<^sub>S M = S b *\<^sub>S R a *\<^sub>S M"
  by (metis assms assoc_left(2) swap_lvalues)

lemma butterfly_isProjector:
  \<open>norm x = 1 \<Longrightarrow> isProjector (selfbutter x)\<close>
  by (subst butterfly_proj, simp_all)

lemma teleport:
  assumes [simp]: "norm \<psi> = 1"
  shows "hoare (teleport_pre \<psi>) (teleport a b) (teleport_post \<psi>)"
proof -
  define XZ :: \<open>bit domain_end\<close> where "XZ = (if a=1 then (if b=1 then pauliZ o\<^sub>C\<^sub>L pauliX else pauliX) else (if b=1 then pauliZ else idOp))"

  define pre where "pre = EQ XAB \<psi>"

  define O1 where "O1 = EQP \<Phi> \<beta>00"
  have \<open>teleport_pre \<psi> = O1 *\<^sub>S pre\<close>
    unfolding pre_def O1_def teleport_pre_def EQ_def EQP_def
    apply (subst compatible_proj_intersect[where R=XAB and S=\<Phi>])
       apply (simp_all add: butterfly_isProjector)
    apply (subst swap_lvalues[where R=XAB and S=\<Phi>])
    by (simp_all add: assoc_left(2))

  also
  define O2 where "O2 = X\<Phi>1 CNOT o\<^sub>C\<^sub>L O1"
  have \<open>hoare (O1 *\<^sub>S pre) [apply CNOT X\<Phi>1] (O2 *\<^sub>S pre)\<close>
    apply (rule hoare_apply) by (simp add: O2_def assoc_left(2))

  also
  define O3 where \<open>O3 = X hadamard o\<^sub>C\<^sub>L O2\<close>
  have \<open>hoare (O2 *\<^sub>S pre) [apply hadamard X] (O3 *\<^sub>S pre)\<close>
    apply (rule hoare_apply) by (simp add: O3_def assoc_left(2))

  also
  define O4 where \<open>O4 = EQP \<Phi>1 (ket a) o\<^sub>C\<^sub>L O3\<close>
  have \<open>hoare (O3 *\<^sub>S pre) [ifthen \<Phi>1 a] (O4 *\<^sub>S pre)\<close>
    apply (rule hoare_ifthen) by (simp add: O4_def assoc_left(2))

  also
  define O5 where \<open>O5 = EQP X (ket b) o\<^sub>C\<^sub>L O4\<close>
  have O5: \<open>O5 = X\<Phi>1 (butterfly (ket b \<otimes>\<^sub>s ket a) (CNOT *\<^sub>V (hadamard *\<^sub>V ket b) \<otimes>\<^sub>s ket a)) \<circ>\<^sub>d O1\<close> (is "_ = ?rhs")
  proof -
    have "O5 = EQP X\<Phi>1 (ket (b,a)) o\<^sub>C\<^sub>L O3"
      unfolding O5_def O4_def
      apply (subst join_EQP', simp)
      by simp
    also have \<open>\<dots> = ?rhs\<close>
      unfolding O3_def O2_def EQP_def
      using [[simp_trace_new]]
      by (simp add: butterfly_times_right to_X\<Phi>1 times_applyOp tensor_op_adjoint tensor_op_ell2 flip: tensor_ell2_ket)
    finally show ?thesis by -
  qed
  have \<open>hoare (O4 *\<^sub>S pre) [ifthen X b] (O5 *\<^sub>S pre)\<close>
    apply (rule hoare_ifthen) by (simp add: O5_def assoc_left(2))

  also
  define O6 where \<open>O6 = \<Phi>2 (if a=1 then pauliX else idOp) o\<^sub>C\<^sub>L O5\<close>
  have \<open>hoare (O5 *\<^sub>S pre) [apply (if a=1 then pauliX else idOp) (\<Phi> \<circ> Snd)] (O6 *\<^sub>S pre)\<close>
    apply (rule hoare_apply) by (auto simp add: O6_def assoc_left(2))

  also
  define O7 where \<open>O7 = \<Phi>2 (if b = 1 then pauliZ else idOp) o\<^sub>C\<^sub>L O6\<close>
  have O7: \<open>O7 = \<Phi>2 XZ o\<^sub>C\<^sub>L O5\<close>
    by (auto simp add: O6_def O7_def XZ_def lvalue_mult)
  have \<open>hoare (O6 *\<^sub>S pre) [apply (if b=1 then pauliZ else idOp) (\<Phi> \<circ> Snd)] (O7 *\<^sub>S pre)\<close>
    apply (rule hoare_apply) 
    by (auto simp add: O7_def assoc_left(2))

  finally have hoare: \<open>hoare (teleport_pre \<psi>) (teleport a b) (O7 *\<^sub>S pre)\<close>
    by (auto simp add: teleport_def comp_def)

  have O5': "O5 = (1/2) *\<^sub>C \<Phi>2 (XZ*) o\<^sub>C\<^sub>L X\<Phi>2 Uswap o\<^sub>C\<^sub>L \<Phi> (butterfly (ket a \<otimes>\<^sub>s ket b) \<beta>00)"
    unfolding O7 O5 O1_def EQP_def XZ_def
    apply (simp split del: if_split only: to_X\<Phi> lvalue_mult[of X\<Phi>])
    apply (simp split del: if_split add: lvalue_mult[of X\<Phi>] 
                flip: complex_vector.linear_scale
                del: pair_apply comp_apply)
    apply (rule arg_cong[of _ _ X\<Phi>])
    apply (rule cblinfun_eq_mat_of_cblinfunI)
    apply (simp add: assoc_def mat_of_cblinfun_assoc_ell2 mat_of_cblinfun_tensor_op butterfly_def' cblinfun_of_mat_timesOp mat_of_cblinfun_ell2_to_l2bounded canonical_basis_length_ell2_def mat_of_cblinfun_adjoint' vec_of_onb_enum_ket cblinfun_of_mat_id swap_sandwich[abs_def]  mat_of_cblinfun_scaleR mat_of_cblinfun_scalarMult tensor_maps_hom_sandwich2 vec_of_onb_enum_tensor_state mat_of_cblinfun_description)
    by normalization

  have [simp]: "unitary XZ"
    unfolding unitary_def unfolding XZ_def apply auto
    apply (metis assoc_left(1) pauliXX pauliZZ times_idOp2)
    by (metis assoc_left(1) pauliXX pauliZZ times_idOp2)

  have O7': "O7 = (1/2) *\<^sub>C X\<Phi>2 Uswap o\<^sub>C\<^sub>L \<Phi> (butterfly (ket a \<otimes>\<^sub>s ket b) \<beta>00)"
    unfolding O7 O5'
    by (simp add: cblinfun_apply_assoc[symmetric] lvalue_mult[of \<Phi>2] del: comp_apply)

  have "O7 *\<^sub>S pre = X\<Phi>2 Uswap *\<^sub>S EQP XAB \<psi> *\<^sub>S \<Phi> (butterfly (ket (a, b)) \<beta>00) *\<^sub>S \<top>"
    apply (simp add: O7' pre_def EQ_def EQP_def cblinfun_apply_assoc_subspace)
    apply (subst swap_lvalues_applySpace[where R=\<Phi> and S=XAB], simp)
    by simp
  also have \<open>\<dots> \<le> X\<Phi>2 Uswap *\<^sub>S EQP XAB \<psi> *\<^sub>S \<top>\<close>
    by (simp add: applyOpSpace_mono)
  also have \<open>\<dots> = EQP \<Phi>2AB \<psi> *\<^sub>S X\<Phi>2 Uswap *\<^sub>S \<top>\<close>
  proof -
    have \<open>X\<Phi>2 Uswap *\<^sub>S EQP XAB \<psi> *\<^sub>S \<top> = (X\<Phi>2;AB) (Uswap \<otimes> idOp) *\<^sub>S EQP XAB \<psi> *\<^sub>S \<top>\<close>
      by (simp add: pair_apply)
    also have \<open>\<dots> = (X\<Phi>2;AB) (Uswap \<otimes> idOp) *\<^sub>S (X\<Phi>2;AB) (TODO selfbutter \<psi>) *\<^sub>S \<top>\<close>
      sorry    
    also have \<open>\<dots> \<le> (X\<Phi>2;AB) (Uswap \<otimes> idOp) *\<^sub>S EQP XAB \<psi> *\<^sub>S (X\<Phi>2;AB) (Uswap \<otimes> idOp) *\<^sub>S \<top>\<close>
      sorry
    show ?thesis sorry
  qed
  also have \<open>\<dots> \<le> EQ \<Phi>2AB \<psi>\<close>
    by (simp add: EQ_def applyOpSpace_mono)
  finally have \<open>O7 *\<^sub>S pre \<le> teleport_post \<psi>\<close>
    by (simp add: teleport_post_def)

  with hoare
  show ?thesis
    by (meson basic_trans_rules(31) hoare_def less_eq_clinear_space.rep_eq)
qed

end


locale concrete_teleport_vars begin

type_synonym a_state = "64 word"
type_synonym b_state = "1000000 word"
type_synonym mem = "a_state * bit * bit * b_state * bit"
type_synonym 'a var = \<open>('a,mem) maps_hom\<close>

definition A :: "a_state var" where \<open>A a = a \<otimes> idOp \<otimes> idOp \<otimes> idOp \<otimes> idOp\<close>
definition X :: \<open>bit var\<close> where \<open>X a = idOp \<otimes> a \<otimes> idOp \<otimes> idOp \<otimes> idOp\<close>
definition \<Phi>1 :: \<open>bit var\<close> where \<open>\<Phi>1 a = idOp \<otimes> idOp \<otimes> a \<otimes> idOp \<otimes> idOp\<close>
definition B :: \<open>b_state var\<close> where \<open>B a = idOp \<otimes> idOp \<otimes> idOp \<otimes> a \<otimes> idOp\<close>
definition \<Phi>2 :: \<open>bit var\<close> where \<open>\<Phi>2 a = idOp \<otimes> idOp \<otimes> idOp \<otimes> idOp \<otimes> a\<close>
end


interpretation teleport_concrete:
  concrete_teleport_vars +
  teleport_locale concrete_teleport_vars.X
                  \<open>pair concrete_teleport_vars.\<Phi>1 concrete_teleport_vars.\<Phi>2\<close>
                  concrete_teleport_vars.A
                  concrete_teleport_vars.B
  apply standard
  using [[simproc del: compatibility_warn]]
  by (auto simp: concrete_teleport_vars.X_def[abs_def]
                 concrete_teleport_vars.\<Phi>1_def[abs_def]
                 concrete_teleport_vars.\<Phi>2_def[abs_def]
                 concrete_teleport_vars.A_def[abs_def]
                 concrete_teleport_vars.B_def[abs_def]
           intro!: compatible3' compatible3)

thm teleport
thm teleport_def


end
