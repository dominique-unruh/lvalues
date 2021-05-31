section \<open>Classical instantiation of registerss\<close>

(* AXIOM INSTANTIATION (use instantiate_laws.py to generate Laws_Classical.thy)
 
   domain \<rightarrow> type

   Generic laws about registers \<rightarrow> Generic laws about registers, instantiated classically
*)

theory Axioms_Classical
  imports Main HOL.Map
begin

type_synonym 'a update = \<open>'a \<rightharpoonup> 'a\<close>

typ \<open>int update\<close>

(* TODO: direct instantiation *)
abbreviation (input) comp_update :: "'a update \<Rightarrow> 'a update \<Rightarrow> 'a update" where
  "comp_update a b \<equiv> a \<circ>\<^sub>m b"

abbreviation (input) id_update :: "'a update" where
  "id_update \<equiv> Some"

lemma id_update_left: "comp_update id_update a = a"
  by (auto intro!: ext simp add: map_comp_def option.case_eq_if)
lemma id_update_right: "comp_update a id_update = a"
  by auto

lemma comp_update_assoc: "comp_update (comp_update a b) c = comp_update a (comp_update b c)"
  by (auto intro!: ext simp add: map_comp_def option.case_eq_if)

type_synonym ('a,'b) preregister = \<open>'a update \<Rightarrow> 'b update\<close>
definition preregister :: \<open>('a,'b) preregister \<Rightarrow> bool\<close> where
  \<open>preregister F \<longleftrightarrow> (\<exists>g s. \<forall>a m. F a m = (case a (g m) of None \<Rightarrow> None | Some x \<Rightarrow> s x m))\<close>

lemma id_preregister: \<open>preregister id\<close>
  unfolding preregister_def
  apply (rule exI[of _ \<open>\<lambda>m. m\<close>])
  apply (rule exI[of _ \<open>\<lambda>a m. Some a\<close>])
  by (simp add: option.case_eq_if)

lemma preregister_mult_right: \<open>preregister (\<lambda>a. comp_update a z)\<close>
  unfolding preregister_def 
  apply (rule exI[of _ \<open>\<lambda>m. the (z m)\<close>])
  apply (rule exI[of _ \<open>\<lambda>x m. case z m of None \<Rightarrow> None | _ \<Rightarrow> Some x\<close>])
  by (auto simp add: option.case_eq_if)

lemma preregister_mult_left: \<open>preregister (\<lambda>a. comp_update z a)\<close>
  unfolding preregister_def 
  apply (rule exI[of _ \<open>\<lambda>m. m\<close>])
  apply (rule exI[of _ \<open>\<lambda>x m. z x\<close>])
  by (auto simp add: option.case_eq_if)

lemma comp_preregister: "preregister (G \<circ> F)" if "preregister F" and \<open>preregister G\<close>
proof -
  from \<open>preregister F\<close>
  obtain sF gF where F: \<open>F a m = (case a (gF m) of None \<Rightarrow> None | Some x \<Rightarrow> sF x m)\<close> for a m
    using preregister_def by blast
  from \<open>preregister G\<close>
  obtain sG gG where G: \<open>G a m = (case a (gG m) of None \<Rightarrow> None | Some x \<Rightarrow> sG x m)\<close> for a m
    using preregister_def by blast
  define s g where \<open>s a m = (case sF a (gG m) of None \<Rightarrow> None | Some x \<Rightarrow> sG x m)\<close>
    and \<open>g m = gF (gG m)\<close> for a m
  have \<open>(G \<circ> F) a m = (case a (g m) of None \<Rightarrow> None | Some x \<Rightarrow> s x m)\<close> for a m
    unfolding F G s_def g_def
    by (auto simp add: option.case_eq_if)
  then show "preregister (G \<circ> F)"
    using preregister_def by blast
qed

definition rel_prod :: "('a*'b) set => ('c*'d) set => (('a*'c) * ('b*'d)) set" where
  "rel_prod a b = (\<lambda>((a,b),(c,d)). ((a,c),(b,d))) ` (a \<times> b)"

definition tensor_update :: \<open>'a update \<Rightarrow> 'b update \<Rightarrow> ('a\<times>'b) update\<close> where
  \<open>tensor_update a b m = (case a (fst m) of None \<Rightarrow> None | Some x \<Rightarrow> (case b (snd m) of None \<Rightarrow> None | Some y \<Rightarrow> Some (x,y)))\<close>

lemma tensor_update_mult: \<open>comp_update (tensor_update a c) (tensor_update b d) = tensor_update (comp_update a b) (comp_update c d)\<close>
  by (auto intro!: ext simp add: map_comp_def option.case_eq_if tensor_update_def)

lemma tensor_extensionality:
  assumes \<open>preregister F\<close>
  assumes \<open>preregister G\<close>
  assumes \<open>\<And>a b. F (tensor_update a b) = G (tensor_update a b)\<close>
  shows "F = G"
proof (rule ccontr)
  assume neq: \<open>F \<noteq> G\<close>
  then obtain ab m where neq': \<open>F ab m \<noteq> G ab m\<close> 
    apply atomize_elim by auto
  from \<open>preregister F\<close>
  obtain gF sF where gsF: \<open>F ab m = (case ab (gF m) of None \<Rightarrow> None | Some x \<Rightarrow> sF x m)\<close> for ab m
    using preregister_def by blast
  from \<open>preregister G\<close>
  obtain gG sG where gsG: \<open>G ab m = (case ab (gG m) of None \<Rightarrow> None | Some x \<Rightarrow> sG x m)\<close> for ab m
    using preregister_def by blast
  consider (eq) \<open>gF m = gG m\<close>
    | (F) x where \<open>ab (gF m) = Some x\<close> \<open>ab (gG m) = None\<close>
    | (G) x where \<open>ab (gG m) = Some x\<close> \<open>ab (gF m) = None\<close>
    by -
  then show False
  proof cases
    case eq
    define a b where \<open>a x = (if x = fst (gF m) then map_option fst (ab (gF m)) else None)\<close> 
      and \<open>b y = (if y = snd (gF m) then map_option snd (ab (gF m)) else None)\<close> for x y
    have Fab: \<open>F ab m = F (tensor_update a b) m\<close>
      unfolding a_def b_def
      by (smt (z3) gsF map_option_is_None option.case(1) option.case(2) option.exhaust_sel option.map(2) prod.collapse tensor_update_def)
    have Gab: \<open>G ab m = G (tensor_update a b) m\<close>
      unfolding a_def b_def eq
      by (smt (z3) gsG map_option_is_None option.case(2) option.case_eq_if option.exhaust_sel option.map(2) prod.collapse tensor_update_def)
    show False
      using Fab Gab assms neq' by presburger
  next
    case F
    define a b where \<open>a x = (if x = fst (gF m) then map_option fst (ab (gF m)) else None)\<close> 
      and \<open>b y = (if y = snd (gF m) then map_option snd (ab (gF m)) else None)\<close> for x y
    have Fab: \<open>F ab m = F (tensor_update a b) m\<close>
      unfolding a_def b_def
      by (smt (z3) gsF map_option_is_None option.case(1) option.case(2) option.exhaust_sel option.map(2) prod.collapse tensor_update_def)
    have G: \<open>G ab m = None\<close>
      by (simp add: F(2) gsG)
    have Gab: \<open>G (tensor_update a b) m = None\<close>
      unfolding a_def b_def
      by (smt (z3) F(1) F(2) gsG is_none_simps(1) is_none_simps(2) option.case_eq_if prod.collapse tensor_update_def)
    show False
      using Fab G Gab assms(3) neq' by presburger
  next
    case G
    define a b where \<open>a x = (if x = fst (gG m) then map_option fst (ab (gG m)) else None)\<close> 
      and \<open>b y = (if y = snd (gG m) then map_option snd (ab (gG m)) else None)\<close> for x y
    have Gab: \<open>G ab m = G (tensor_update a b) m\<close>
      unfolding a_def b_def
      by (simp add: G(1) gsG tensor_update_def)
    have F: \<open>F ab m = None\<close>
      using G(2) gsF by fastforce
    have Fab: \<open>F (tensor_update a b) m = None\<close>
      unfolding a_def b_def
      by (smt (z3) G(1) G(2) gsF option.case_eq_if option.simps(3) prod.collapse tensor_update_def)
    show False
      using F Fab Gab assms(3) neq' by fastforce
  next
  qed
qed

definition "valid_getter_setter g s \<longleftrightarrow> 
  (\<forall>b. b = s (g b) b) \<and> (\<forall>a b. g (s a b) = a) \<and> (\<forall>a a' b. s a (s a' b) = s a b)"

definition \<open>register_from_getter_setter g s a m = (case a (g m) of None \<Rightarrow> None | Some x \<Rightarrow> Some (s x m))\<close>
definition \<open>register_apply F a = the o F (Some o a)\<close>
definition \<open>getter_setter F = (let s = (\<lambda>a. register_apply F (\<lambda>_. a)) in ((\<lambda>m. THE x. s x m = m), s))\<close> for F :: \<open>'a update \<Rightarrow> 'b update\<close>

lemma getter_setter_of_register_from_getter_setter:
  assumes \<open>valid_getter_setter g s\<close>
  shows \<open>getter_setter (register_from_getter_setter g s) = (g, s)\<close>
proof -
  define g' s' where \<open>g' = fst (getter_setter (register_from_getter_setter g s))\<close>
    and \<open>s' = snd (getter_setter (register_from_getter_setter g s))\<close>
  have \<open>s = s'\<close>
    by (auto intro!:ext simp: s'_def getter_setter_def register_apply_def register_from_getter_setter_def)
  moreover have \<open>g = g'\<close>
  proof (rule ext, rename_tac m)
    fix m
    have \<open>g' m = (THE x. s x m = m)\<close>
      by (auto intro!:ext simp: g'_def getter_setter_def register_apply_def register_from_getter_setter_def)
    moreover have \<open>s (g m) m = m\<close>
      by (metis assms valid_getter_setter_def)
    moreover have \<open>x = x'\<close> if \<open>s x m = m\<close> \<open>s x' m = m\<close> for x x'
      by (metis assms that(1) that(2) valid_getter_setter_def)
    ultimately show \<open>g m = g' m\<close>
      by (simp add: Uniq_def the1_equality')
  qed
  ultimately show ?thesis
    unfolding s'_def g'_def by (metis surjective_pairing) 
qed

definition register :: \<open>('a,'b) preregister \<Rightarrow> bool\<close> where
  \<open>register F \<longleftrightarrow> (\<exists>g s. F = register_from_getter_setter g s \<and> valid_getter_setter g s)\<close>

lemma register_id: \<open>register F \<Longrightarrow> F id_update = id_update\<close>
  by (auto simp add: register_def valid_getter_setter_def register_from_getter_setter_def)

lemma register_tensor_left: \<open>register (\<lambda>a. tensor_update a id_update)\<close>
  apply (auto simp: register_def)
  apply (rule exI[of _ fst])
  apply (rule exI[of _ \<open>\<lambda>x' (x,y). (x',y)\<close>])
  by (auto intro!: ext simp add: tensor_update_def valid_getter_setter_def register_from_getter_setter_def option.case_eq_if)

lemma register_tensor_right: \<open>register (\<lambda>a. tensor_update id_update a)\<close>
  apply (auto simp: register_def)
  apply (rule exI[of _ snd])
  apply (rule exI[of _ \<open>\<lambda>y' (x,y). (x,y')\<close>])
  by (auto intro!: ext simp add: tensor_update_def valid_getter_setter_def register_from_getter_setter_def option.case_eq_if)

lemma register_preregister: "preregister F" if \<open>register F\<close>
proof -
  from \<open>register F\<close>
  obtain s g where F: \<open>F a m = (case a (g m) of None \<Rightarrow> None | Some x \<Rightarrow> Some (s x m))\<close> for a m
    unfolding register_from_getter_setter_def register_def by blast
  show ?thesis
    unfolding preregister_def
    apply (rule exI[of _ g])
    apply (rule exI[of _ \<open>\<lambda>x m. Some (s x m)\<close>])
    using F by simp
qed

lemma register_comp: "register (G \<circ> F)" if \<open>register F\<close> and \<open>register G\<close>
  for F :: "('a,'b) preregister" and G :: "('b,'c) preregister"
proof -
  from \<open>register F\<close>
  obtain sF gF where F: \<open>F a m = (case a (gF m) of None \<Rightarrow> None | Some x \<Rightarrow> Some (sF x m))\<close>
    and validF: \<open>valid_getter_setter gF sF\<close> for a m
    unfolding register_def register_from_getter_setter_def by blast
  from \<open>register G\<close>
  obtain sG gG where G: \<open>G a m = (case a (gG m) of None \<Rightarrow> None | Some x \<Rightarrow> Some (sG x m))\<close>
    and validG: \<open>valid_getter_setter gG sG\<close> for a m
    unfolding register_def register_from_getter_setter_def by blast
  define s g where \<open>s a m = sG (sF a (gG m)) m\<close> and \<open>g m = gF (gG m)\<close> for a m
  have \<open>(G \<circ> F) a m = (case a (g m) of None \<Rightarrow> None | Some x \<Rightarrow> Some (s x m))\<close> for a m
    by (auto simp add: option.case_eq_if F G s_def g_def)
  moreover have \<open>valid_getter_setter g s\<close>
    using validF validG by (auto simp: valid_getter_setter_def s_def g_def)
  ultimately show "register (G \<circ> F)"
    unfolding register_def register_from_getter_setter_def by blast
qed

lemma register_mult: "register F \<Longrightarrow> comp_update (F a) (F b) = F (comp_update a b)"
  by (auto intro!: ext simp: register_def register_from_getter_setter_def[abs_def] valid_getter_setter_def map_comp_def option.case_eq_if)

definition register_pair ::
  \<open>('a update \<Rightarrow> 'c update) \<Rightarrow> ('b update \<Rightarrow> 'c update) \<Rightarrow> (('a\<times>'b) update \<Rightarrow> 'c update)\<close> where
  \<open>register_pair F G = (let (gF, sF) = getter_setter F; (gG, sG) = getter_setter G in
    register_from_getter_setter (\<lambda>m. (gF m, gG m)) (\<lambda>(a,b) m. sF a (sG b m)))\<close>

lemma compatible_setter:
  assumes [simp]: \<open>register F\<close> \<open>register G\<close>
  assumes compat: \<open>\<And>a b. comp_update (F a) (G b) = comp_update (G b) (F a)\<close>
  shows \<open>snd (getter_setter F) x o snd (getter_setter G) y = snd (getter_setter G) y o snd (getter_setter F) x\<close>
  using compat apply (auto intro!: ext simp: getter_setter_def register_apply_def o_def map_comp_def)
  by (smt (verit, best) assms(1) assms(2) option.case_eq_if option.distinct(1) register_def register_from_getter_setter_def)

lemma register_pair_apply:
  assumes [simp]: \<open>register F\<close> \<open>register G\<close>
  assumes \<open>\<And>a b. comp_update (F a) (G b) = comp_update (G b) (F a)\<close>
  shows \<open>(register_pair F G) (tensor_update a b) = comp_update (F a) (G b)\<close>
proof -
  obtain gF sF gG sG where gsF: \<open>getter_setter F = (gF, sF)\<close> and gsG: \<open>getter_setter G = (gG, sG)\<close>
    by (metis surj_pair)
  then have validF: \<open>valid_getter_setter gF sF\<close> and validG: \<open>valid_getter_setter gG sG\<close>
    by (metis assms fst_conv getter_setter_of_register_from_getter_setter register_def snd_conv)+
  then have F: \<open>F = register_from_getter_setter gF sF\<close> and G: \<open>G = register_from_getter_setter gG sG\<close>
    by (metis Pair_inject assms getter_setter_of_register_from_getter_setter gsF gsG register_def)+
  have gFsG: \<open>gF (sG y m) = gF m\<close> for y m
  proof -
    have \<open>gF (sG y m) = gF (sG y (sF (gF m) m))\<close>
      using validF by (metis valid_getter_setter_def)
    also have \<open>\<dots> = gF (sF (gF m) (sG y m))\<close>
      by (smt (verit, best) assms(1) assms(2) assms(3) comp_apply compatible_setter gsF gsG snd_conv)
    also have \<open>\<dots> = gF m\<close>
      by (metis validF valid_getter_setter_def)
    finally show ?thesis by -
  qed

  show ?thesis
    apply (subst (2) F, subst (2) G)
    by (auto intro!:ext simp: register_pair_def gsF gsG tensor_update_def map_comp_def option.case_eq_if
              register_from_getter_setter_def gFsG)
qed

lemma register_pair_is_register:
  fixes F :: \<open>'a update \<Rightarrow> 'c update\<close> and G
  assumes [simp]: \<open>register F\<close> and [simp]: \<open>register G\<close>
  assumes compat: \<open>\<And>a b. comp_update (F a) (G b) = comp_update (G b) (F a)\<close>
  shows \<open>register (register_pair F G)\<close>
proof -
  obtain gF sF gG sG where gsF: \<open>getter_setter F = (gF, sF)\<close> and gsG: \<open>getter_setter G = (gG, sG)\<close>
    by (metis surj_pair)
  then have validF: \<open>valid_getter_setter gF sF\<close> and validG: \<open>valid_getter_setter gG sG\<close>
    by (metis assms case_prodD case_prodI getter_setter_of_register_from_getter_setter register_def)+
  then have \<open>valid_getter_setter (\<lambda>m. (gF m, gG m)) (\<lambda>(a, b) m. sF a (sG b m))\<close>
    apply (auto simp: valid_getter_setter_def) (* Sledgehammer proof: *)
    apply (smt (verit, best) assms(1) assms(2) comp_apply compat compatible_setter gsF gsG snd_conv)
    by (smt (verit, best) assms(1) assms(2) comp_apply compat compatible_setter gsF gsG snd_conv)
  then show ?thesis
    by (auto simp: register_pair_def gsF gsG register_def)
qed

end
