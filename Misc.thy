theory Misc
  imports Bounded_Operators.Bounded_Operators_Code "HOL-Library.Z2"
    Jordan_Normal_Form.Matrix
begin

unbundle no_vec_syntax
unbundle no_inner_syntax
unbundle cblinfun_notation
unbundle jnf_notation

lemma cbounded_linear_equal_ket:
  fixes f g :: \<open>'a::finite ell2 \<Rightarrow> _\<close>
  assumes \<open>clinear f\<close>
  assumes \<open>clinear g\<close>
  assumes \<open>\<And>i. f (ket i) = g (ket i)\<close>
  shows \<open>f = g\<close>
  apply (rule ext)
  apply (rule complex_vector.linear_eq_on_span[where f=f and g=g and B=\<open>range ket\<close>])
  using assms apply auto
  by (metis ket_ell2_span span_finite_dim finite_class.finite_UNIV finite_imageI iso_tuple_UNIV_I) 

lemma cbounded_linear_finite_ell2[simp, intro!]:
  fixes f :: \<open>'a::finite ell2 \<Rightarrow> 'b::complex_normed_vector\<close>
  assumes "clinear f"
  shows \<open>cbounded_linear f\<close>
  apply (subst cblinfun_operator_finite_dim[where basis=\<open>ket ` UNIV\<close>])
  using assms apply (auto intro!: cindependent_ket)
  by (metis finite_class.finite_UNIV finite_imageI iso_tuple_UNIV_I ket_ell2_span span_finite_dim)

lemma apply_cblinfun_distr_left: "(A + B) *\<^sub>V x = A *\<^sub>V x + B *\<^sub>V x"
  apply transfer by simp

lemma ket_Kronecker_delta: \<open>\<langle>ket i, ket j\<rangle> = (if i=j then 1 else 0)\<close>
  by (simp add: ket_Kronecker_delta_eq ket_Kronecker_delta_neq)


(* definition \<open>butter i j = vector_to_cblinfun (ket i) o\<^sub>C\<^sub>L (vector_to_cblinfun (ket j) :: complex \<Rightarrow>\<^sub>C\<^sub>L _)*\<close> *)
abbreviation "butterket i j \<equiv> butterfly (ket i) (ket j)"

lemma sum_butter[simp]: \<open>(\<Sum>(i::'a::finite)\<in>UNIV. butterket i i) = idOp\<close>
  apply (rule equal_ket)
  apply (subst complex_vector.linear_sum[where f=\<open>\<lambda>y. y *\<^sub>V ket _\<close>])
  apply (auto simp add: apply_cblinfun_distr_left clinearI butterfly_def' times_applyOp ket_Kronecker_delta)
  apply (subst sum.mono_neutral_cong_right[where S=\<open>{_}\<close>])
  by auto

lemma linfun_cspan: \<open>cspan {butterket i j| (i::'b::finite) (j::'a::finite). True} = UNIV\<close>
proof (rule, simp, rule)
  fix f :: \<open>'a ell2 \<Rightarrow>\<^sub>C\<^sub>L 'b ell2\<close>
  have frep: \<open>f = (\<Sum>(i,j)\<in>UNIV. \<langle>ket j, f *\<^sub>V ket i\<rangle> *\<^sub>C (butterket j i))\<close>
  proof (rule cblinfun_ext)
    fix \<phi> :: \<open>'a ell2\<close>
    have \<open>f *\<^sub>V \<phi> = f *\<^sub>V (\<Sum>i\<in>UNIV. butterket i i) *\<^sub>V \<phi>\<close>
      by auto
    also have \<open>\<dots> = (\<Sum>i\<in>UNIV. f *\<^sub>V butterket i i *\<^sub>V \<phi>)\<close>
      apply (subst (2) complex_vector.linear_sum)
       apply (simp add: cblinfun_apply_add clinearI plus_cblinfun.rep_eq)
      by simp
    also have \<open>\<dots> = (\<Sum>i\<in>UNIV. (\<Sum>j\<in>UNIV. butterket j j) *\<^sub>V f *\<^sub>V butterket i i *\<^sub>V \<phi>)\<close>
      by simp
    also have \<open>\<dots> = (\<Sum>i\<in>UNIV. \<Sum>j\<in>UNIV. butterket j j *\<^sub>V f *\<^sub>V butterket i i *\<^sub>V \<phi>)\<close>
      apply (subst (5) complex_vector.linear_sum)
       apply (simp add: cblinfun_apply_add clinearI plus_cblinfun.rep_eq)
      by simp
    also have \<open>\<dots> = (\<Sum>(i,j)\<in>UNIV. butterket j j *\<^sub>V f *\<^sub>V butterket i i *\<^sub>V \<phi>)\<close>
      by (simp add: sum.cartesian_product)
    also have \<open>\<dots> = (\<Sum>(i,j)\<in>UNIV. \<langle>ket j, f *\<^sub>V ket i\<rangle> *\<^sub>C (butterket j i *\<^sub>V \<phi>))\<close>
      by (simp add: butterfly_def' times_applyOp mult.commute)
    also have \<open>\<dots> = (\<Sum>(i,j)\<in>UNIV. \<langle>ket j, f *\<^sub>V ket i\<rangle> *\<^sub>C (butterket j i)) *\<^sub>V \<phi>\<close>
      unfolding applyOp_scaleC1[symmetric] case_prod_beta
      thm complex_vector.linear_sum
      apply (subst complex_vector.linear_sum[where f=\<open>\<lambda>x. x *\<^sub>V \<phi>\<close>])
       apply (simp add: apply_cblinfun_distr_left clinearI)
      by simp
    finally show \<open>f *\<^sub>V \<phi> = (\<Sum>(i,j)\<in>UNIV. \<langle>ket j, f *\<^sub>V ket i\<rangle> *\<^sub>C (butterket j i)) *\<^sub>V \<phi>\<close>
      by -
  qed
  show \<open>f \<in> cspan {butterket i j |i j. True}\<close>
    apply (subst frep)
    apply (auto simp: case_prod_beta)
    by (metis (mono_tags, lifting) complex_vector.span_base complex_vector.span_scale complex_vector.span_sum mem_Collect_eq)
qed

definition bra :: "'a \<Rightarrow> (_,complex) cblinfun" where "bra i = vector_to_cblinfun (ket i)*" for i

lemma linfun_cindependent: \<open>cindependent {butterket i j| (i::'b::finite) (j::'a::finite). True}\<close>
proof (rule independent_if_scalars_zero)
  show finite: \<open>finite {butterket (i::'b) (j::'a) |i j. True}\<close>
    apply (subst (6) conj.left_neutral[symmetric])
    apply (rule finite_image_set2)
    by auto
  fix f :: \<open>('a ell2 \<Rightarrow>\<^sub>C\<^sub>L 'b ell2) \<Rightarrow> complex\<close> and g :: \<open>'a ell2 \<Rightarrow>\<^sub>C\<^sub>L 'b ell2\<close>
  define lin where \<open>lin = (\<Sum>g\<in>{butterket i j |i j. True}. f g *\<^sub>C g)\<close>
  assume \<open>lin = 0\<close>
  assume \<open>g \<in> {butterket i j |i j. True}\<close>
  then obtain i j where g: \<open>g = butterket i j\<close>
    by auto
  (* define bra :: "'b \<Rightarrow> (_,complex) cblinfun" where "bra i = vector_to_cblinfun (ket i)*" for i *)

  have *: "bra i *\<^sub>V f g *\<^sub>C g *\<^sub>V ket j = 0"
    if \<open>g\<in>{butterket i j |i j. True} - {butterket i j}\<close> for g 
  proof -
    from that
    obtain i' j' where g: \<open>g = butterket i' j'\<close>
      by auto
    from that have \<open>g \<noteq> butterket i j\<close> by auto
    with g consider (i) \<open>i\<noteq>i'\<close> | (j) \<open>j\<noteq>j'\<close>
      by auto
    then show \<open>bra i *\<^sub>V f g *\<^sub>C g *\<^sub>V ket j = 0\<close>
    proof cases
      case i
      then show ?thesis 
        unfolding g by (auto simp: butterfly_def' times_applyOp bra_def ket_Kronecker_delta_neq)
    next
      case j
      then show ?thesis
        unfolding g by (auto simp: butterfly_def' times_applyOp ket_Kronecker_delta_neq)
    qed
  qed

  have \<open>0 = bra i *\<^sub>V lin *\<^sub>V ket j\<close>
    using \<open>lin = 0\<close> by auto
  also have \<open>\<dots> = (\<Sum>g\<in>{butterket i j |i j. True}. bra i *\<^sub>V (f g *\<^sub>C g) *\<^sub>V ket j)\<close>
    unfolding lin_def
    apply (rule complex_vector.linear_sum)
    by (simp add: cblinfun_apply_add clinearI plus_cblinfun.rep_eq)
  also have \<open>\<dots> = (\<Sum>g\<in>{butterket i j}. bra i *\<^sub>V (f g *\<^sub>C g) *\<^sub>V ket j)\<close>
    apply (rule sum.mono_neutral_right)
    using finite * by auto
  also have \<open>\<dots> = bra i *\<^sub>V (f g *\<^sub>C g) *\<^sub>V ket j\<close>
    by (simp add: g)
  also have \<open>\<dots> = f g\<close>
    unfolding g 
    by (auto simp: butterfly_def' times_applyOp bra_def ket_Kronecker_delta_eq)
  finally show \<open>f g = 0\<close>
    by simp
qed

lemma clinear_eq_butterketI:
  fixes F G :: \<open>('a::finite ell2 \<Rightarrow>\<^sub>C\<^sub>L 'b::finite ell2) \<Rightarrow> 'c::complex_vector\<close>
  assumes "clinear F" and "clinear G"
  assumes "\<And>i j. F (butterket i j) = G (butterket i j)"
  shows "F = G"
 apply (rule complex_vector.linear_eq_on_span[where f=F, THEN ext, rotated 3])
     apply (subst linfun_cspan)
  using assms by auto


(* Declares the ML antiquotation @{fact ...}. In ML code,
  @{fact f} for a theorem/fact name f is replaced by an ML string
  containing a printable(!) representation of fact. (I.e.,
  if you print that string using writeln, the user can ctrl-click on it.)
 *)
setup \<open>ML_Antiquotation.inline_embedded \<^binding>\<open>fact\<close>
((Args.context -- Scan.lift Args.name_position) >> (fn (ctxt,namepos) => let
  val facts = Proof_Context.facts_of ctxt
  val fullname = Facts.check (Context.Proof ctxt) facts namepos
  val (markup, shortname) = Proof_Context.markup_extern_fact ctxt fullname
  val string = Markup.markups markup shortname
  in ML_Syntax.print_string string end
))
\<close>


instantiation bit :: enum begin
definition "enum_bit = [0::bit,1]"
definition "enum_all_bit P \<longleftrightarrow> P (0::bit) \<and> P 1"
definition "enum_ex_bit P \<longleftrightarrow> P (0::bit) \<or> P 1"
instance
  apply intro_classes
  apply (auto simp: enum_bit_def enum_all_bit_def enum_ex_bit_def)
  by (metis bit_not_one_imp)+
end

lemma card_bit[simp]: "CARD(bit) = 2"
  using card_2_iff' by force

instantiation bit :: card_UNIV begin
definition "finite_UNIV = Phantom(bit) True"
definition "card_UNIV = Phantom(bit) 2"
instance
  apply intro_classes
  by (simp_all add: finite_UNIV_bit_def card_UNIV_bit_def)
end

lemma sum_single: 
  assumes "finite A"
  assumes "\<And>j. j \<noteq> i \<Longrightarrow> j\<in>A \<Longrightarrow> f j = 0"
  shows "sum f A = (if i\<in>A then f i else 0)"
  apply (subst sum.mono_neutral_cong_right[where S=\<open>A \<inter> {i}\<close> and h=f])
  using assms by auto

lemma mat_of_rows_list_carrier[simp]:
  "mat_of_rows_list n vs \<in> carrier_mat (length vs) n"
  "dim_row (mat_of_rows_list n vs) = length vs"
  "dim_col (mat_of_rows_list n vs) = n"
  unfolding mat_of_rows_list_def by auto

lemma dim_vec_vec_of_onb_enum[simp]: "dim_vec (vec_of_onb_enum (a :: 'a::enum ell2)) = CARD('a)"
  by (metis canonical_basis_length_ell2_def canonical_basis_length_eq dim_vec_of_onb_enum_list')


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

term vec_index
term "($)"

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

lemma mat_of_cblinfun_ell2_carrier[simp]: \<open>mat_of_cblinfun (a::'a::enum ell2 \<Rightarrow>\<^sub>C\<^sub>L 'b::enum ell2) \<in> carrier_mat CARD('b) CARD('a)\<close>
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


lemma cblinfun_eq_mat_of_cblinfunI: 
  assumes "mat_of_cblinfun a = mat_of_cblinfun b"
  shows "a = b"
  by (metis assms mat_of_cblinfun_inverse)

lemma butterfly_times_right: "butterfly \<psi> \<phi> o\<^sub>C\<^sub>L a = butterfly \<psi> (a* *\<^sub>V \<phi>)"
  unfolding butterfly_def'
  by (simp add: cblinfun_apply_assoc vector_to_cblinfun_applyOp)  


lemma butterfly_isProjector:
  \<open>norm x = 1 \<Longrightarrow> isProjector (selfbutter x)\<close>
  by (subst butterfly_proj, simp_all)

end
