From Coq          Require Import Lists.List.
From Coq          Require Import String.
From Coq          Require Import Vectors.Vector.
From CryptolToCoq Require Import SAWCoreScaffolding.
From CryptolToCoq Require Import SAWCoreVectorsAsCoqVectors.
From CryptolToCoq Require Import SAWCoreBitvectors.
From CryptolToCoq Require Import SAWCorePrelude.
From CryptolToCoq Require Import SpecMExtra.
From EnTree       Require Import Automation.
Import SAWCorePrelude.
Import SpecMNotations.
Local Open Scope entree_scope.

(* (* All of this for BoolDecidableEqDepSet.UIP, from:
   https://stackoverflow.com/questions/50924127/record-equality-in-coq *)
From Coq Require Import Logic.Eqdep_dec.
Module BoolDecidableSet <: DecidableSet.
Definition U := bool.
Definition eq_dec := Bool.bool_dec.
End BoolDecidableSet.
Module BoolDecidableEqDepSet := DecidableEqDepSet BoolDecidableSet. *)

Require Import Examples.mbox_gen.
Import mbox.

Instance QuantType_Mbox : QuantType Mbox.
Admitted.


(* QOL: nicer names for bitvector and mbox arguments *)
#[local] Hint Extern 901 (IntroArg Any (bitvector _) _) =>
  let e := fresh "x" in IntroArg_intro e : refines prepostcond. 
#[local] Hint Extern 901 (IntroArg Any Mbox _) =>
  let e := fresh "m" in IntroArg_intro e : refines prepostcond. 
#[local] Hint Extern 901 (IntroArg Any Mbox_def _) =>
  let e := fresh "m" in IntroArg_intro e : refines prepostcond.


(* Maybe automation - FIXME move to EnTree.Automation *)

Lemma spec_refines_maybe_l (E1 E2 : EvType) Γ1 Γ2 R1 R2
  (RPre : SpecPreRel E1 E2 Γ1 Γ2) (RPost : SpecPostRel E1 E2 Γ1 Γ2)
  RR A t1 k1 mb (t2 : SpecM E2 Γ2 R2) :
  (mb = Nothing _ -> spec_refines RPre RPost RR t1 t2) ->
  (forall a, mb = Just _ a -> spec_refines RPre RPost RR (k1 a) t2) ->
  spec_refines RPre RPost RR (maybe A (SpecM E1 Γ1 R1) t1 k1 mb) t2.
Proof. destruct mb; intros; eauto. Qed.

Lemma spec_refines_maybe_r (E1 E2 : EvType) Γ1 Γ2 R1 R2
  (RPre : SpecPreRel E1 E2 Γ1 Γ2) (RPost : SpecPostRel E1 E2 Γ1 Γ2)
  RR (t1 : SpecM E1 Γ1 R1) A t2 k2 mb :
  (mb = Nothing _ -> spec_refines RPre RPost RR t1 t2) ->
  (forall a, mb = Just _ a -> spec_refines RPre RPost RR t1 (k2 a)) ->
  spec_refines RPre RPost RR t1 (maybe A (SpecM E2 Γ2 R2) t2 k2 mb).
Proof. destruct mb; intros; eauto. Qed.

Definition spec_refines_maybe_l_IntroArg (E1 E2 : EvType) Γ1 Γ2 R1 R2
  (RPre : SpecPreRel E1 E2 Γ1 Γ2) (RPost : SpecPostRel E1 E2 Γ1 Γ2)
  RR A t1 k1 mb (t2 : SpecM E2 Γ2 R2) :
  (IntroArg Hyp (mb = Nothing _) (fun _ => spec_refines RPre RPost RR t1 t2)) ->
  (IntroArg Any A (fun a => IntroArg Hyp (mb = Just _ a) (fun _ =>
   spec_refines RPre RPost RR (k1 a) t2))) ->
  spec_refines RPre RPost RR (maybe A (SpecM E1 Γ1 R1) t1 k1 mb) t2 :=
  spec_refines_maybe_l E1 E2 Γ1 Γ2 R1 R2 RPre RPost RR A t1 k1 mb t2.

Definition spec_refines_maybe_r_IntroArg (E1 E2 : EvType) Γ1 Γ2 R1 R2
  (RPre : SpecPreRel E1 E2 Γ1 Γ2) (RPost : SpecPostRel E1 E2 Γ1 Γ2)
  RR (t1 : SpecM E1 Γ1 R1) A t2 k2 mb :
  (IntroArg Hyp (mb = Nothing _) (fun _ => spec_refines RPre RPost RR t1 t2)) ->
  (IntroArg Any A (fun a => IntroArg Hyp (mb = Just _ a) (fun _ =>
   spec_refines RPre RPost RR t1 (k2 a)))) ->
  spec_refines RPre RPost RR t1 (maybe A (SpecM E2 Γ2 R2) t2 k2 mb) :=
  spec_refines_maybe_r E1 E2 Γ1 Γ2 R1 R2 RPre RPost RR t1 A t2 k2 mb.

#[global] Hint Extern 101 (spec_refines _ _ _ (maybe _ _ _ _ _) _) =>
  simple apply spec_refines_maybe_l_IntroArg : refines.
#[global] Hint Extern 101 (spec_refines _ _ _ _ (maybe _ _ _ _ _)) =>
  simple apply spec_refines_maybe_r_IntroArg : refines.

Lemma IntroArg_eq_Nothing_const n A (goal : Prop)
  : goal -> IntroArg n (Nothing A = Nothing A) (fun _ => goal).
Proof. intros H eq; eauto. Qed.
Lemma IntroArg_eq_Just_const n A (x y : A) (goal : Prop)
  : IntroArg n (x = y) (fun _ => goal) ->
    IntroArg n (Just A x = Just A y) (fun _ => goal).
Proof. intros H eq; apply H; injection eq; eauto. Qed.
Lemma IntroArg_eq_Nothing_Just n A (x : A) goal
  : IntroArg n (Nothing A = Just A x) goal.
Proof. intros eq; discriminate eq. Qed.
Lemma IntroArg_eq_Just_Nothing n A (x : A) goal
  : IntroArg n (Just A x = Nothing A) goal.
Proof. intros eq; discriminate eq. Qed.

#[global] Hint Extern 101 (IntroArg _ (Nothing _ = Nothing _) _) =>
  simple apply IntroArg_eq_Nothing_const : refines.
#[global] Hint Extern 101 (IntroArg _ (Just _ _ = Just _ _) _) =>
  simple apply IntroArg_eq_Just_const : refines.
#[global] Hint Extern 101 (IntroArg _ (Nothing _ = Just _ _) _) =>
  apply IntroArg_eq_Nothing_Just : refines.
#[global] Hint Extern 101 (IntroArg _ (Just _ _ = Nothing _) _) =>
  apply IntroArg_eq_Just_Nothing : refines.

  
(* Boolean equality automation *)

Lemma simpl_llvm_bool_eq (b : bool) :
  not (bvEq 1 (if b then intToBv 1 (-1) else intToBv 1 0) (intToBv 1 0)) = b.
Proof. destruct b; eauto. Qed.

Definition simpl_llvm_bool_eq_IntroArg n (b1 b2 : bool) (goal : Prop) :
  IntroArg n (b1 = b2) (fun _ => goal) ->
  IntroArg n (not (bvEq 1 (if b1 then intToBv 1 (-1) else intToBv 1 0) (intToBv 1 0)) = b2) (fun _ => goal).
Proof. rewrite simpl_llvm_bool_eq; eauto. Defined.

#[local] Hint Extern 101 (IntroArg _ (not (bvEq 1 (if _ then intToBv 1 (-1) else intToBv 1 0) (intToBv 1 0)) = _) _) =>
  simple eapply simpl_llvm_bool_eq_IntroArg : refines.


(* Mbox destruction automation *)

Lemma refinesM_either_unfoldMbox_nil_l (E1 E2 : EvType) Γ1 Γ2 R1 R2
  (RPre : SpecPreRel E1 E2 Γ1 Γ2) (RPost : SpecPostRel E1 E2 Γ1 Γ2)
  (RR : Rel R1 R2) f g (P : SpecM E2 Γ2 R2) :
  spec_refines RPre RPost RR (f tt) P ->
  spec_refines RPre RPost RR (either _ _ _ f g (unfoldMbox Mbox_nil)) P.
Proof. eauto. Qed.

Lemma refinesM_either_unfoldMbox_cons_l (E1 E2 : EvType) Γ1 Γ2 R1 R2
  (RPre : SpecPreRel E1 E2 Γ1 Γ2) (RPost : SpecPostRel E1 E2 Γ1 Γ2)
  (RR : Rel R1 R2) strt len m d f g (P : SpecM E2 Γ2 R2) :
  spec_refines RPre RPost RR (g (strt, (len, (m, d)))) P ->
  spec_refines RPre RPost RR (either _ _ _ f g (unfoldMbox (Mbox_cons strt len m d))) P.
Proof. eauto. Qed.

Ltac either_unfoldMbox m :=
  lazymatch m with
  | Mbox_nil =>
    simple apply refinesM_either_unfoldMbox_nil_l
  | Mbox_cons ?strt ?len ?m0 ?d =>
    simple apply (refinesM_either_unfoldMbox_cons_l _ _ _ _ _ _ _ _ _ strt len m0 d)
  | _ => let strt := fresh "strt" in
         let len  := fresh "len" in
         let m0   := fresh "m" in
         let d    := fresh "d" in destruct m as [| strt len m0 d ];
                                  [ either_unfoldMbox Mbox_nil
                                  | either_unfoldMbox (Mbox_cons strt len m0 d) ];
                                  simpl foldMbox; cbn [ Mbox__rec Mbox_rect ] in *;
                                  unfold SAWCoreScaffolding.fst, SAWCoreScaffolding.snd;
                                  cbn [ Datatypes.fst Datatypes.snd projT1 ]
  end.

Global Hint Extern 100 (spec_refines _ _ _ (either _ _ _ _ _ (unfoldMbox ?m)) _) =>
  either_unfoldMbox m : refines.
Global Hint Extern 100 (spec_refines _ _ _ _ (either _ _ _ _ _ (unfoldMbox ?m))) =>
  either_unfoldMbox m : refines.

Lemma transMbox_Mbox_nil_r m : transMbox m Mbox_nil = m.
Proof.
  induction m; eauto.
  simpl; f_equal; eauto.
Qed.

Lemma transMbox_assoc m1 m2 m3 :
  transMbox (transMbox m1 m2) m3 = transMbox m1 (transMbox m2 m3).
Proof.
  induction m1; eauto.
  simpl; f_equal; eauto.
Qed.

Hint Rewrite transMbox_Mbox_nil_r (*transMbox_assoc*) : refines.


(* Helper functions and lemmas *)

Definition mbox_chain_length := 
  Mbox_rect (fun _ => nat) O (fun _ _ _ rec _ => S rec).

Lemma mbox_chain_length_transMbox m1 m2 :
  mbox_chain_length (transMbox m1 m2) = mbox_chain_length m1 + mbox_chain_length m2.
Proof. induction m1; simpl; eauto. Qed.


(** * mbox_free_chain *)

Lemma mbox_free_chain_spec_ref m
  : spec_refines eqPreRel eqPostRel eq
      (mbox_free_chain m)
      (total_spec (fun _ => True) (fun _ r => r = intToBv 32 0) (1, m)).
Proof.
  unfold mbox_free_chain, mbox_free_chain__bodies, mboxFreeSpec.
  prove_refinement.
  - wellfounded_decreasing_nat.
    exact (a + mbox_chain_length m0).
  - prepost_case 0 0.
    + exact (m0 = m1 /\ a = 1).
    + exact (r = r0).
    prepost_case 1 0.
    + exact (m0 = m1 /\ a = 0).
    + exact (r = r0).
    prepost_exclude_remaining.
  - prove_refinement_continue.
Qed.


(** * mbox_concat *)

Definition mbox_concat_spec (x y : Mbox) : Mbox :=
  Mbox_rect _ Mbox_nil (fun strt len _ _ d => Mbox_cons strt len y d) x.

Lemma mbox_concat_spec_ref m1 m2
  : spec_refines eqPreRel eqPostRel eq
      (mbox_concat m1 m2)
      (total_spec (fun _ => True)
                  (fun '(m1', m2') r => r = mbox_concat_spec m1' m2')
                  (m1, m2)).
Proof.
  unfold mbox_concat, mbox_concat__bodies.
  prove_refinement.
  - wellfounded_none.
  - prepost_case 0 0.
    + exact (m = m3 /\ m0 = m4).
    + exact (r = r0).
    prepost_exclude_remaining.
  - prove_refinement_continue.
Qed.

#[local] Hint Resolve mbox_concat_spec_ref : refines_proofs.


(** * mbox_concat_chains *)

Lemma mbox_rect_identity m :
  Mbox_rect _ Mbox_nil (fun strt len _ rec d => Mbox_cons strt len rec d) m = m.
Proof. induction m; simpl; try f_equal; eauto. Qed. 

Definition mbox_concat_chains_spec (m1 m2 : Mbox) : Mbox :=
  if mbox_chain_length m1 =? 0 then Mbox_nil else transMbox m1 m2.

Lemma mbox_concat_chains_spec_ref__dec_args m1 m2
  : spec_refines eqPreRel eqPostRel eq
      (mbox_concat_chains m1 m2)
      (total_spec (fun _ => True)
                  (fun '(_, m, m1', m2') r => r = mbox_concat_chains_spec (transMbox m m1') m2')
                  (1, Mbox_nil, m1, m2)).
Proof.
  unfold mbox_concat_chains, mbox_concat_chains__bodies, mbox_concat_chains_spec.
  prove_refinement.
  - wellfounded_decreasing_nat.
    exact (a + mbox_chain_length m0).
  - prepost_case 0 0.
    + exact (Mbox_nil = m3 /\ m = m4 /\ m0 = m5 /\ a = 1).
    + exact (r = r0).
    prepost_case 1 0.
    + exact (m = m4 /\ Mbox_cons x x0 m3 a = m5 /\ m0 = m6 /\ a0 = 0).
    + exact (r = r0).
    prepost_exclude_remaining.
  - prove_refinement_continue.
    + rewrite mbox_chain_length_transMbox, Nat.add_comm; simpl.
      rewrite mbox_rect_identity.
      rewrite transMbox_assoc; reflexivity.
    + rewrite transMbox_assoc; reflexivity.
Qed.

Lemma mbox_concat_chains_spec_ref__fuel m1 m2
  : spec_refines eqPreRel eqPostRel eq
      (mbox_concat_chains m1 m2)
      (total_spec (fun _ => True)
                  (fun '(_, m1', m2') r => r = mbox_concat_chains_spec m1' m2')
                  (mbox_chain_length m1, m1, m2)).
Proof.
  unfold mbox_concat_chains, mbox_concat_chains__bodies, mbox_concat_chains_spec.
  prove_refinement.
  - wellfounded_decreasing_nat.
    exact a.
  - prepost_case 0 0.
    + exact (m = m3 /\ m0 = m4 /\ a = mbox_chain_length m).
    + exact (r = r0).
    prepost_case 1 0.
    + exact (transMbox m (Mbox_cons x x0 m3 a) = m4 /\ m0 = m5 /\
             a0 = mbox_chain_length m3).
    + exact (r = r0).
    prepost_exclude_remaining.
  - prove_refinement_continue.
    + rewrite mbox_chain_length_transMbox, Nat.add_comm; simpl.
      rewrite mbox_rect_identity.
      rewrite transMbox_assoc; reflexivity.
    + rewrite transMbox_assoc; reflexivity.
Qed.


(** * mbox_detach *)

Definition mbox_detach_spec : Mbox -> Mbox * Mbox :=
  Mbox_rect _ (Mbox_nil, Mbox_nil)
              (fun strt len next _ d => (next, (Mbox_cons strt len Mbox_nil d))).

Lemma mbox_detach_spec_ref m
  : spec_refines eqPreRel eqPostRel eq
      (mbox_detach m)
      (total_spec (fun _ => True)
                  (fun m r => r = mbox_detach_spec m) m).
Proof.
  unfold mbox_detach, mbox_detach__bodies.
  prove_refinement.
  - wellfounded_none.
  - prepost_case 0 0.
    + exact (m0 = m1).
    + exact (r = r0).
    prepost_exclude_remaining.
  - prove_refinement_continue.
Qed.


(** * mbox_drop *)

Definition mbox_drop_spec : Mbox -> bitvector 64 -> Mbox :=
  Mbox_rect _ (fun _ => Mbox_nil) (fun strt len next rec d ix =>
    if bvule 64 len ix
    then Mbox_cons (intToBv 64 0) (intToBv 64 0) (rec (bvSub 64 ix len)) d
    else Mbox_cons (bvAdd 64 strt ix) (bvSub 64 len ix) next d).

Lemma mbox_drop_spec_ref m x
  : spec_refines eqPreRel eqPostRel eq
      (mbox_drop m x)
      (total_spec (fun _ => True)
                  (fun '(m, x) r => r = mbox_drop_spec m x)
                  (m, x)).
Proof.
  unfold mbox_drop, mbox_drop__bodies, mbox_drop_spec.
  prove_refinement.
  - wellfounded_decreasing_nat.
    exact (mbox_chain_length m0).
  - prepost_case 0 0.
    + exact (m0 = m1 /\ x0 = x1).
    + exact (r = r0).
    prepost_exclude_remaining.
  - prove_refinement_continue.
    all: rewrite e_if; reflexivity.
Qed.


(** * mbox_len *)

Definition mbox_len_spec : Mbox -> bitvector 64 :=
  Mbox__rec (fun _ =>  bitvector 64) (intToBv 64 0)
          (fun strt len m rec d => bvAdd 64 rec len).

Lemma mbox_len_spec_transMbox m1 m2 :
  mbox_len_spec (transMbox m1 m2) =
  bvAdd 64 (mbox_len_spec m1) (mbox_len_spec m2).
Proof.
  induction m1 as [|strt len m1' IH d]; simpl.
  - rewrite bvAdd_id_l.
    reflexivity.
  - rewrite IH.
    rewrite 2 bvAdd_assoc.
    rewrite (bvAdd_comm _ len).
    reflexivity.
Qed.

Lemma mbox_len_spec_ref__dec_args m
  : spec_refines eqPreRel eqPostRel eq
      (mbox_len m)
      (total_spec (fun _ => True)
                  (fun '(_, m1', m2') r => r = (transMbox m1' m2', mbox_len_spec (transMbox m1' m2')))
                  (1, Mbox_nil, m)).
Proof.
  unfold mbox_len, mbox_len__bodies, Mbox_def.
  prove_refinement.
  - wellfounded_decreasing_nat.
    exact (a + mbox_chain_length m1).
  - prepost_case 0 0.
    + exact (m0 = m2 /\ m1 = Mbox_nil /\ 1 = a).
    + exact (r = r0).
  - prepost_case 1 0.
    + exact (m0 = m2 /\ m1 = m3 /\ 0 = a
              /\ mbox_len_spec m0 = x).
    + exact (r = r0).
    prepost_exclude_remaining.
  - prove_refinement_continue.
    + rewrite H.
      rewrite transMbox_Mbox_nil_r.
      reflexivity.
    + rewrite mbox_len_spec_transMbox.
      simpl.
      rewrite bvAdd_id_l.
      reflexivity.
    + rewrite H.
      rewrite transMbox_Mbox_nil_r.
      rewrite transMbox_assoc.
      reflexivity.
Qed.

Lemma mbox_len_spec_ref__fuel m
  : spec_refines eqPreRel eqPostRel eq
      (mbox_len m)
      (total_spec (fun _ => True)
                  (fun '(_, _, m') r => r = (m', mbox_len_spec m'))
                  (1, mbox_chain_length m, m)).
Proof.
  unfold mbox_len, mbox_len__bodies, Mbox_def.
  prove_refinement.
  - wellfounded_decreasing_nat.
    exact (a + a0).
  - prepost_case 0 0.
    + exact (m0 = m1 /\ 1 = a /\ mbox_chain_length m0 = a0).
    + exact (r = r0).
  - prepost_case 1 0.
    + exact (transMbox m0 m1 = m2 /\ 0 = a /\ mbox_chain_length m1 = a0
              /\ mbox_len_spec m0 = x).
    + exact (r = r0).
    prepost_exclude_remaining.
  - prove_refinement_continue.
    + rewrite H.
      rewrite transMbox_Mbox_nil_r.
      reflexivity.
    + rewrite mbox_len_spec_transMbox.
      simpl.
      rewrite bvAdd_id_l.
      reflexivity.
    + rewrite H.
      rewrite transMbox_Mbox_nil_r.
      rewrite transMbox_assoc.
      reflexivity.
Qed.

(** * mbox_randomize *)

Definition mbox_head_len_sub_strt : Mbox -> nat :=
  Mbox_rect (fun _ => nat) 0 (fun strt len _ _ _ =>
    bvToNat 64 (bvSub 64 len strt)).

Definition mbox_randomize_precond : Mbox -> Prop :=
  Mbox_rect (fun _ => Prop) True (fun strt len _ _ _ =>
    (* 0 <= strt <= len < 128 *)
    isBvsle 64 (intToBv 64 0) strt /\ isBvsle 64 strt len /\
    isBvslt 64 len (intToBv 64 128)).

Definition SUCCESS         := intToBv 32 0.
Definition MBOX_NULL_ERROR := intToBv 32 23.

(* - If `m` is non-null, the function returns `SUCCESS` and `m->data` is set to
     some `data'` such that `m->data[i] = data'[i]` for all `i` such that
     `i < m->strt` or `i >= m->len`.
   - Otherwise, the function returns `MBOX_NULL_ERROR`. *)
Definition mbox_randomize_postcond m r : Prop :=
  Mbox_rect (fun _ => Prop)
            (r = (Mbox_nil, MBOX_NULL_ERROR))
            (fun strt len m _ d =>
              exists d', (forall i (pf : isBvult 64 i bv64_128),
                           isBvslt 64 i strt \/ isBvsle 64 len i ->
                           atBVVec _ _ _ d i pf = atBVVec _ _ _ d' i pf)
                         /\ r = (Mbox_cons strt len m d', SUCCESS)) m.

Definition mbox_randomize_invar (strt len i : bitvector 64) : Prop :=
  (* strt <= i <= len *)
  isBvsle 64 strt i /\ isBvsle 64 i len.

Lemma mbox_randomize_spec_ref m
  : spec_refines eqPreRel eqPostRel eq
      (mbox_randomize m)
      (total_spec (fun '(_, m') => mbox_randomize_precond m')
                  (fun '(_, m') r => mbox_randomize_postcond m' r)
                  (1 + mbox_head_len_sub_strt m, m)).
Proof.
  unfold mbox_randomize, mbox_randomize__bodies, randSpec.
  prove_refinement.
  - wellfounded_decreasing_nat.
    exact a.
  - prepost_case 0 0.
    + exact (m0 = m1 /\ a = 1 + mbox_head_len_sub_strt m0).
    + exact (r = r0).
    prepost_case 1 0.
    + exact (mbox_randomize_invar x x0 x1 /\
             Mbox_cons x x0 m0 a = m1 /\
             a0 = bvToNat 64 (bvSub 64 x0 x1)).
    + exact (r = r0).
    prepost_exclude_remaining.
  - unfold mbox_head_len_sub_strt, mbox_randomize_precond,
           mbox_randomize_postcond, mbox_randomize_invar in *.
    prove_refinement_continue.
    (* FIXME: Why don't these `Mbox_rect`s get unfolded?? *)
    all: cbn [ Mbox_rect ] in * |-;
         try match goal with
         | |- Mbox_rect _ _ _ _ => cbn [ Mbox_rect ] in *; split; eauto
         end.
    (* FIXME: Once the above is fixed, add automatic destruction of exists, etc. *)
    all: try (destruct H2 as [d' []]); try (eexists; split; intros).
    + apply H2; eauto.
    + rewrite transMbox_Mbox_nil_r in H3; eauto.
    + apply H2; eauto.
    + rewrite transMbox_Mbox_nil_r in H3; eauto.
    all: admit.
Admitted.




(* ========================================================================== *)


Definition mbox_randomize_precond : Mbox -> Prop :=
  Mbox__rec (fun _ => Prop) True (fun strt len _ _ _ =>
    (* 0 <= strt <= len < 128 *)
    isBvsle 64 (intToBv 64 0) strt /\ isBvsle 64 strt len /\
    isBvslt 64 len (intToBv 64 128)).

Definition mbox_randomize_invar (strt len i : bitvector 64) : Prop :=
  (* 0 <= strt <= i <= len < 128 *)
  isBvsle 64 (intToBv 64 0) strt /\ isBvsle 64 strt i /\
  isBvsle 64 i len /\ isBvslt 64 len (intToBv 64 128).

Lemma no_errors_mbox_randomize
  : refinesFun mbox_randomize (fun m => assumingM (mbox_randomize_precond m) noErrorsSpec).
Proof.
  unfold mbox_randomize, mbox_randomize__tuple_fun, mbox_randomize_precond.
  prove_refinement_match_letRecM_l.
  - exact (fun strt len m d i => assumingM (mbox_randomize_invar strt len i) noErrorsSpec).
  unfold noErrorsSpec, randSpec, mbox_randomize_invar.
  time "no_errors_mbox_randomize" prove_refinement.
  (* All the `Mbox_def` and `Vec 32 bool` goals are only every used in *)
  (* impossible cases, so they can be set to whatever Coq chooses. These *)
  (* calls to `assumption` also take care of showing that the loop invariant *)
  (* holds initially from our precondition, and a few of the cases of showing *)
  (* that the loop invariant holds inductively (see below). *)
  all: try assumption.
  (* Showing the error case of the array bounds check is impossible by virtue *)
  (* of our loop invariant *)
  - assert (isBvsle 64 (intToBv 64 0) a4) by (rewrite e_assuming0; eauto).
    assert (isBvsle 64 (intToBv 64 0) a1) by (rewrite H; eauto).
    apply isBvult_to_isBvslt_pos in e_if; eauto.
    assert (isBvult 64 a4 (intToBv 64 128)).
    + apply isBvult_to_isBvslt_pos; [ eauto | reflexivity | ].
      rewrite e_if; eauto.
    + rewrite H1 in e_maybe; discriminate e_maybe.
  (* Showing the loop invariant holds inductively (the remaining two cases) *)
  - rewrite e_assuming1; apply isBvsle_suc_r.
    rewrite e_assuming2, e_assuming3.
    reflexivity.
  - apply isBvslt_to_isBvsle_suc.
    apply isBvult_to_isBvslt_pos in e_if.
    + assumption.
    + rewrite e_assuming0; eauto.
    + rewrite e_assuming0, e_assuming1; eauto.
  (* Showing the error case of the overflow check is impossible by virtue of *)
  (* our loop invariant *)
  - rewrite <- e_assuming1, <- e_assuming0 in e_if0.
    vm_compute in e_if0; discriminate e_if0.
  - rewrite e_assuming2, e_assuming3 in e_if0.
    vm_compute in e_if0; discriminate e_if0.
  - destruct a; inversion e_either. destruct e_assuming; assumption.
  - destruct a; inversion e_either. destruct e_assuming as [ Ha1 [ Ha2 Ha3 ]].
    assumption.
  - destruct a; inversion e_either. destruct e_assuming as [ Ha1 [ Ha2 Ha3 ]].
    assumption.
Qed.

(*
  In English, the spec for `mbox_randomize m` is:
  - If `m` is non-null, the function returns `SUCCESS` and `m->data` is set to
    some `data'` such that `m->data[i] = data'[i]` for all `i` such that
    `i < m->strt` or `i >= m->len`.
  - Otherwise, the function returns MBOX_NULL_ERROR.
*)

Definition SUCCESS         := intToBv 32 0.
Definition MBOX_NULL_ERROR := intToBv 32 23.

Definition mbox_randomize_non_null_spec strt len m d : CompM (Mbox * bitvector 32) :=
  existsM (fun d' => assertM (forall i (pf : isBvult 64 i bv64_128),
                                isBvslt 64 i strt \/ isBvsle 64 len i ->
                                atBVVec _ _ _ d i pf = atBVVec _ _ _ d' i pf) >>
                     returnM (Mbox_cons strt len m d', SUCCESS)).

Definition mbox_randomize_spec : Mbox -> CompM (Mbox * bitvector 32) :=
  Mbox__rec (fun _ => CompM (Mbox * bitvector 32))
          (returnM (Mbox_nil, MBOX_NULL_ERROR))
          (fun strt len m _ d => mbox_randomize_non_null_spec strt len m d).

Lemma mbox_randomize_spec_ref :
  refinesFun mbox_randomize (fun m => assumingM (mbox_randomize_precond m) (mbox_randomize_spec m)).
Proof.
  unfold mbox_randomize, mbox_randomize__tuple_fun, mbox_randomize_precond, mbox_randomize_spec.
  prove_refinement_match_letRecM_l.
  - exact (fun strt len m d i =>
             assumingM (mbox_randomize_invar strt len i)
                       (mbox_randomize_non_null_spec strt len m d)).
  unfold noErrorsSpec, randSpec, mbox_randomize_invar.
  time "mbox_randomize_spec_ref" prove_refinement.
  (* All but the noted cases are the same as `no_errors_mbox_randomize` above *)
  all: try assumption.
  (* Showing the error case of the array bounds check is impossible by virtue *)
  (* of our loop invariant *)
  - assert (isBvsle 64 (intToBv 64 0) a4) by (rewrite e_assuming0; eauto).
    assert (isBvsle 64 (intToBv 64 0) a1) by (rewrite H; eauto).
    apply isBvult_to_isBvslt_pos in e_if; eauto.
    assert (isBvult 64 a4 (intToBv 64 128)).
    + apply isBvult_to_isBvslt_pos; [ eauto | reflexivity | ].
      rewrite e_if; eauto.
    + rewrite H1 in e_maybe; discriminate e_maybe.
  (* Showing the loop invariant holds inductively (the remaining two cases) *)
  - rewrite e_assuming1; apply isBvsle_suc_r.
    rewrite e_assuming2, e_assuming3.
    reflexivity.
  - apply isBvslt_to_isBvsle_suc.
    apply isBvult_to_isBvslt_pos in e_if.
    + assumption.
    + rewrite e_assuming0; eauto.
    + rewrite e_assuming0, e_assuming1; eauto.
  (* Unique to this proof: Showing our spec works for the recursive case *)
  - rewrite transMbox_Mbox_nil_r; simpl.
    unfold mbox_randomize_non_null_spec.
    prove_refinement.
    + exact e_exists0.
    + prove_refinement; intros.
      rewrite <- e_assert; eauto.
      unfold updBVVec; rewrite at_gen_BVVec.
      enough (bvEq 64 i a4 = false) by (rewrite H0; reflexivity).
      destruct H.
      * apply isBvslt_to_bvEq_false.
        rewrite e_assuming1 in H; eauto.
      * rewrite bvEq_sym.
        apply isBvslt_to_bvEq_false.
        apply isBvult_to_isBvslt_pos in e_if.
        -- rewrite H in e_if; eauto.
        -- rewrite e_assuming0; eauto.
        -- rewrite e_assuming0, e_assuming1; eauto.
  (* Showing the error case of the overflow check is impossible by virtue of *)
  (* our loop invariant *)
  - rewrite <- e_assuming1, <- e_assuming0 in e_if0.
    vm_compute in e_if0; discriminate e_if0.
  - rewrite e_assuming2, e_assuming3 in e_if0.
    vm_compute in e_if0; discriminate e_if0.
  (* Unique to this proof: Showing our spec works for the base case *)
  - rewrite transMbox_Mbox_nil_r; simpl.
    unfold mbox_randomize_non_null_spec.
    prove_refinement.
    + exact a3.
    + prove_refinement.
  - destruct a; try discriminate. reflexivity.
  - destruct a; inversion e_either.
    destruct e_assuming as [ Ha1 [ Ha2 Ha3 ]]. assumption.
  - destruct a; inversion e_either.
    destruct e_assuming as [ Ha1 [ Ha2 Ha3 ]]. assumption.
  - destruct a; inversion e_either.
    destruct e_assuming as [ Ha1 [ Ha2 Ha3 ]]. assumption.
  - destruct a; inversion e_either. simpl. rewrite transMbox_Mbox_nil_r.
    reflexivity.
Qed.


Lemma no_errors_mbox_drop
  : refinesFun mbox_drop (fun _ _ => noErrorsSpec).
Proof.
  unfold mbox_drop, mbox_drop__tuple_fun, noErrorsSpec.
  (* Set Ltac Profiling. *)
  time "no_errors_mbox_drop" prove_refinement.
  (* Show Ltac Profile. Reset Ltac Profile. *)
Time Qed.

Definition mbox_drop_spec : Mbox -> bitvector 64 -> Mbox :=
  Mbox__rec _ (fun _ => Mbox_nil) (fun strt len next rec d ix =>
    if bvuge 64 ix len
    then Mbox_cons (intToBv 64 0) (intToBv 64 0) (rec (bvSub 64 ix len)) d
    else Mbox_cons (bvAdd 64 strt ix) (bvSub 64 len ix) next d).

Lemma mbox_drop_spec_ref
  : refinesFun mbox_drop (fun x ix => returnM (mbox_drop_spec x ix)).
Proof.
  unfold mbox_drop, mbox_drop__tuple_fun, mbox_drop_spec.
  (* Set Ltac Profiling. *)
  time "mbox_drop_spec_ref" prove_refinement.
  (* Show Ltac Profile. Reset Ltac Profile. *)
  - simpl. destruct a; try discriminate e_either. reflexivity.
  - simpl. destruct a; try discriminate e_either.
    inversion e_either. simpl. rewrite <- H0 in e_if. simpl in e_if.
    unfold isBvule in e_if. rewrite e_if. simpl.
    repeat rewrite transMbox_Mbox_nil_r.
    reflexivity.
  - destruct a; simpl in e_either; inversion e_either.
    rewrite <- H0 in e_if. simpl in e_if. simpl.
    assert (bvule 64 v0 a0 = false); [ apply isBvult_def_opp; assumption | ].
    rewrite H. simpl. rewrite transMbox_Mbox_nil_r.
    reflexivity.
Time Qed.


Lemma mbox_free_chain_spec_ref
  : refinesFun mbox_free_chain (fun _ => returnM (intToBv 32 0)).
Proof.
  unfold mbox_free_chain, mbox_free_chain__tuple_fun, mboxFreeSpec.
  prove_refinement_match_letRecM_l.
  - exact (fun _ => returnM (intToBv 32 0)).
  (* Set Ltac Profiling. *)
  time "mbox_free_chain_spec_ref" prove_refinement.
  (* Show Ltac Profile. Reset Ltac Profile. *)
Time Qed.

Lemma no_errors_mbox_free_chain
  : refinesFun mbox_free_chain (fun _ => noErrorsSpec).
Proof.
  rewrite mbox_free_chain_spec_ref.
  unfold noErrorsSpec.
  prove_refinement.
Qed.


Lemma no_errors_mbox_concat
  : refinesFun mbox_concat (fun _ _ => noErrorsSpec).
Proof.
  unfold mbox_concat, mbox_concat__tuple_fun, noErrorsSpec.
  (* Set Ltac Profiling. *)
  time "no_errors_mbox_concat" prove_refinement.
  (* Show Ltac Profile. Reset Ltac Profile. *)
Time Qed.

Definition mbox_concat_spec (x y : Mbox) : Mbox :=
  Mbox__rec _ Mbox_nil (fun strt len _ _ d => Mbox_cons strt len y d) x.

Lemma mbox_concat_spec_ref
  : refinesFun mbox_concat (fun x y => returnM (mbox_concat_spec x y)).
Proof.
  unfold mbox_concat, mbox_concat__tuple_fun, mbox_concat_spec.
  (* Set Ltac Profiling. *)
  time "mbox_concat_spec_ref" prove_refinement.
  (* Show Ltac Profile. Reset Ltac Profile. *)
  - destruct a; simpl in e_either; try discriminate e_either. reflexivity.
  - destruct a; simpl in e_either; inversion e_either.
    rewrite transMbox_Mbox_nil_r. reflexivity.
Time Qed.

(* Add `mbox_concat_spec_ref` to the hint database. Unfortunately, Coq will not unfold refinesFun
   and mbox_concat_spec when rewriting, and the only workaround I know right now is this :/ *)
Definition mbox_concat_spec_ref' : ltac:(let tp := type of mbox_concat_spec_ref in
                                         let tp' := eval unfold refinesFun, mbox_concat_spec in tp
                                          in exact tp') := mbox_concat_spec_ref.
Hint Rewrite mbox_concat_spec_ref' : refinement_proofs.


Lemma no_errors_mbox_concat_chains
  : refinesFun mbox_concat_chains (fun _ _ => noErrorsSpec).
Proof.
  unfold mbox_concat_chains, mbox_concat_chains__tuple_fun.
  prove_refinement_match_letRecM_l.
  - exact (fun _ _ _ _ _ _ => noErrorsSpec).
  unfold noErrorsSpec.
  (* Set Ltac Profiling. *)
  time "no_errors_mbox_concat_chains" prove_refinement with NoRewrite.
  (* Show Ltac Profile. Reset Ltac Profile. *)
Time Qed.

Definition mbox_concat_chains_spec (x y : Mbox) : Mbox :=
  Mbox__rec (fun _ => Mbox) Mbox_nil (fun _ _ _ _ _ =>
    Mbox__rec (fun _ => Mbox) x (fun _ _ _ _ _ =>
      transMbox x y) y) x.

Lemma mbox_concat_chains_spec_ref
  : refinesFun mbox_concat_chains (fun x y => returnM (mbox_concat_chains_spec x y)).
Proof.
  unfold mbox_concat_chains, mbox_concat_chains__tuple_fun.
  prove_refinement_match_letRecM_l.
  - intros x y strt len next d.
    exact (returnM (transMbox x (Mbox_cons strt len (transMbox next y) d))).
  unfold mbox_concat_chains_spec.
  time "mbox_concat_chains_spec_ref" prove_refinement.
  - destruct a5; simpl in e_either; inversion e_either.
    repeat rewrite transMbox_Mbox_nil_r; reflexivity.
  - destruct a5; simpl in e_either; inversion e_either.
    repeat rewrite transMbox_Mbox_nil_r; reflexivity.
  - destruct a; simpl in e_either; inversion e_either. reflexivity.
  - destruct a; simpl in e_either; inversion e_either.
    destruct a0; simpl in e_either0; inversion e_either0.
    rewrite transMbox_Mbox_nil_r; reflexivity.
  - destruct a; simpl in e_either; inversion e_either.
    destruct a0; simpl in e_either0; inversion e_either0.
    simpl; repeat rewrite transMbox_Mbox_nil_r; reflexivity.
Time Qed.


Lemma no_errors_mbox_detach
  : refinesFun mbox_detach (fun _ => noErrorsSpec).
Proof.
  unfold mbox_detach, mbox_detach__tuple_fun, noErrorsSpec.
  (* Set Ltac Profiling. *)
  time "no_errors_mbox_detach" prove_refinement.
  (* Show Ltac Profile. Reset Ltac Profile. *)
Time Qed.

Definition mbox_detach_spec : Mbox -> Mbox * Mbox :=
  Mbox__rec _ (Mbox_nil, Mbox_nil)
            (fun strt len next _ d => (next, (Mbox_cons strt len Mbox_nil d))).

Lemma mbox_detach_spec_ref
  : refinesFun mbox_detach (fun x => returnM (mbox_detach_spec x)).
Proof.
  unfold mbox_detach, mbox_detach__tuple_fun, mbox_detach, mbox_detach_spec.
  (* Set Ltac Profiling. *)
  time "mbox_detach_spec_ref" prove_refinement.
  (* Show Ltac Profile. Reset Ltac Profile. *)
  - destruct a; simpl in e_either; inversion e_either. reflexivity.
  - destruct a; simpl in e_either; inversion e_either.
    rewrite transMbox_Mbox_nil_r; reflexivity.
Time Qed.

(* Add `mbox_detach_spec_ref` to the hint database. Unfortunately, Coq will not unfold refinesFun
   and mbox_detach_spec when rewriting, and the only workaround I know right now is this :/ *)
Definition mbox_detach_spec_ref' : ltac:(let tp := type of mbox_detach_spec_ref in
                                         let tp' := eval unfold refinesFun, mbox_detach_spec in tp
                                          in exact tp') := mbox_detach_spec_ref.
Hint Rewrite mbox_detach_spec_ref' : refinement_proofs.


Lemma no_errors_mbox_len
  : refinesFun mbox_len (fun _ => noErrorsSpec).
Proof.
  unfold mbox_len, mbox_len__tuple_fun.
  prove_refinement_match_letRecM_l.
  - exact (fun _ _ _ => noErrorsSpec).
  unfold noErrorsSpec.
  (* Set Ltac Profiling. *)
  time "no_errors_mbox_len" prove_refinement.
  (* Show Ltac Profile. Reset Ltac Profile. *)
Time Qed.

Definition mbox_len_spec : Mbox -> bitvector 64 :=
  Mbox__rec (fun _ =>  bitvector 64) (intToBv 64 0)
          (fun strt len m rec d => bvAdd 64 rec len).

Lemma mbox_len_spec_ref
  : refinesFun mbox_len (fun m => returnM (m, mbox_len_spec m)).
Proof.
  unfold mbox_len, mbox_len__tuple_fun.
  prove_refinement_match_letRecM_l.
  - exact (fun m1 rec m2 => returnM (transMbox m1 m2, bvAdd 64 rec (mbox_len_spec m2))).
  unfold mbox_len_spec.
  (* Set Ltac Profiling. *)
  time "mbox_len_spec_ref" prove_refinement.
  (* Show Ltac Profile. Reset Ltac Profile. *)
  all: try rewrite bvAdd_id_r; try rewrite bvAdd_id_l; try reflexivity.
  - destruct a2; simpl in e_either; inversion e_either.
    repeat rewrite transMbox_Mbox_nil_r. rewrite bvAdd_id_r. reflexivity.
  - destruct a2; simpl in e_either; inversion e_either.
    repeat rewrite transMbox_Mbox_nil_r. simpl.
    rewrite bvAdd_assoc. rewrite (bvAdd_comm _ v0). reflexivity.
  - repeat rewrite transMbox_Mbox_nil_r. reflexivity.
Time Qed.


Definition mbox_copy_precond : Mbox -> Prop :=
  Mbox__rec (fun _ => Prop) True (fun strt len _ _ _ =>
    isBvslt 64 (intToBv 64 0) strt /\ isBvule 64 strt (intToBv 64 128) /\
    isBvule 64 len (bvSub 64 (intToBv 64 128) strt)).

(* This proof takes a bit to complete. Since we're also going to prove spec_ref,
   we can prove no-errors faster using that proof (see below) *)
(* Lemma no_errors_mbox_copy *)
(*   : refinesFun mbox_copy (fun m => assumingM (mbox_copy_precond m) noErrorsSpec). *)
(* Proof. *)
(*   unfold mbox_copy, mbox_copy__tuple_fun, mboxNewSpec. *)
(*   unfold mbox_copy_precond, noErrorsSpec. *)
(*   (* Yikes! The below functions may or may not be defined depending on what *)
(*      machine compiled mbox.bc *) *)
(*   try unfold llvm__x2ememcpy__x2ep0i8__x2ep0i8__x2ei64. *)
(*   try unfold llvm__x2eobjectsize__x2ei64__x2ep0i8, __memcpy_chk. *)
(*   Set Printing Depth 1000. *)
(*   time "no_errors_mbox_copy" prove_refinement with NoRewrite. *)
(*   all: try assumption. *)
(*   - rewrite e_assuming0 in e_maybe. *)
(*     discriminate e_maybe. *)
(*   - rewrite e_assuming1 in e_maybe0. *)
(*     discriminate e_maybe0. *)
(*   - rewrite a in e_maybe1. *)
(*     discriminate e_maybe1. *)
(*   - rewrite e_assuming1 in e_maybe2. *)
(*     discriminate e_maybe2. *)
(*   - rewrite <- e_assuming in e_if. *)
(*     vm_compute in e_if; discriminate e_if. *)
(*   - rewrite <- isBvult_to_isBvslt_pos in e_if. *)
(*     + rewrite e_assuming0 in e_if. *)
(*       vm_compute in e_if; discriminate e_if. *)
(*     + reflexivity. *)
(*     + apply isBvslt_to_isBvsle. *)
(*       assumption. *)
(* Time Qed. *)

Definition empty_mbox_d := genBVVec 64 (intToBv 64 128) (bitvector 8) (fun i _ => bvNat 8 0).

(* TODO give this a better name and explain what it does *)
Definition conjSliceBVVec (strt len : bitvector 64) pf0 pf1 d0 d1 : BVVec 64 bv64_128 (bitvector 8) :=
  updSliceBVVec 64 (intToBv 64 128) _ d0 strt len
    (sliceBVVec 64 (intToBv 64 128) _ strt len pf0 pf1 d1).

(* Given a `start`, `len`, and `dat` of a single Mbox, return an mbox chain consisting of
   a single mbox with `id` 0,  the given `start` and `len`, and the given `dat` with the
   range 0 to `start` zeroed out. *)
Definition mbox_copy_spec_cons strt len m d : CompM (Mbox * Mbox) :=
  assumingM (isBvslt 64 (intToBv 64 0) strt)
    (forallM (fun pf0 : isBvule 64 strt (intToBv 64 128) =>
      (forallM (fun pf1 : isBvule 64 len (bvSub 64 (intToBv 64 128) strt) =>
        returnM (Mbox_cons strt len m
                           (conjSliceBVVec strt len pf0 pf1 d d),
                (Mbox_cons strt len Mbox_nil
                           (conjSliceBVVec strt len pf0 pf1 empty_mbox_d d))))))).

Definition mbox_copy_spec : Mbox -> CompM (Mbox * Mbox) :=
  Mbox__rec (fun _ => CompM  (Mbox * Mbox)) (returnM (Mbox_nil, Mbox_nil))
          (fun strt len m _ d => mbox_copy_spec_cons strt len m d).

Lemma eithers2_either {A B C} (f: A -> C) (g: B -> C) e :
  eithers _ (FunsTo_Cons _ _ f (FunsTo_Cons _ _ g (FunsTo_Nil _))) e =
  either _ _ _ f g e.
Proof.
  destruct e; reflexivity.
Qed.

Lemma mbox_copy_spec_ref : refinesFun mbox_copy mbox_copy_spec.
Proof.
  unfold mbox_copy, mbox_copy__tuple_fun, mboxNewSpec.
  unfold mbox_copy_spec, mbox_copy_spec_cons, empty_mbox_d.
  (* Yikes! The below functions may or may not be defined depending on what
     machine compiled mbox.bc *)
  try unfold llvm__x2ememcpy__x2ep0i8__x2ep0i8__x2ei64.
  try unfold llvm__x2eobjectsize__x2ei64__x2ep0i8, __memcpy_chk.
  Set Printing Depth 1000.
  (* Expect this to take on the order of 15 seconds, removing the `NoRewrite`
     adds another 5 seconds and only simplifies the proof in the one noted spot *)
  (* Set Ltac Profiling. *)
  time "mbox_copy_spec_ref" prove_refinement with NoRewrite.
  (* Show Ltac Profile. Reset Ltac Profile. *)
  all: try discriminate e_either.
  - destruct a; simpl in e_either; inversion e_either. reflexivity.
  - simpl in e_either0. discriminate e_either0.
  - destruct a; simpl in e_either; inversion e_either. simpl.
    apply refinesM_assumingM_r; intro.
    apply refinesM_forallM_r; intro.
    unfold isBvule in a2.
    rewrite <- H0 in e_maybe; simpl in e_maybe.
    rewrite a2 in e_maybe. simpl in e_maybe. discriminate e_maybe.
  - destruct a; simpl in e_either; inversion e_either. simpl.
    apply refinesM_assumingM_r; intro.
    apply refinesM_forallM_r; intro.
    apply refinesM_forallM_r; intro.
    rewrite <- H0 in e_maybe0. simpl in e_maybe0.
    unfold isBvule in a4; rewrite a4 in e_maybe0.
    simpl in e_maybe0. discriminate e_maybe0.
  - destruct a; simpl in e_either; inversion e_either. simpl.
    apply refinesM_assumingM_r; intro.
    apply refinesM_forallM_r; intro.
    apply refinesM_forallM_r; intro.
    rewrite <- H0 in e_maybe1. simpl in e_maybe1.
    unfold isBvule in a4. rewrite a4 in e_maybe1.
    simpl in e_maybe1. discriminate e_maybe1.
  - destruct a; simpl in e_either; inversion e_either. simpl.
    apply refinesM_assumingM_r; intro.
    apply refinesM_forallM_r; intro.
    apply refinesM_forallM_r; intro.
    rewrite <- H0 in e_maybe2. simpl in e_maybe2.
    unfold isBvule in a6. rewrite a6 in e_maybe2.
    simpl in e_maybe2. discriminate e_maybe2.
  - destruct a; simpl in e_either; inversion e_either. simpl.
    prove_refinement with NoRewrite.
    subst a0. simpl. repeat rewrite transMbox_Mbox_nil_r.
    destruct a1; simpl in e_either0; inversion e_either0.
    simpl. unfold conjSliceBVVec.
    replace a4 with e_forall; [ replace a5 with e_forall0;
                                [ reflexivity | ] | ];
    apply BoolDecidableEqDepSet.UIP.
  - elimtype False; apply (not_isBvslt_bvsmin _ _ e_if).
  - elimtype False; apply (not_isBvslt_bvsmax _ _ e_if).
Time Qed.

Lemma no_errors_mbox_copy
  : refinesFun mbox_copy (fun m => assumingM (mbox_copy_precond m) noErrorsSpec).
Proof.
  rewrite mbox_copy_spec_ref.
  unfold mbox_copy_spec, mbox_copy_spec_cons, mbox_copy_precond, noErrorsSpec.
  intro; apply refinesM_assumingM_r; intro e_assuming.
  induction a; simpl in *.
  all: repeat prove_refinement.
Qed.

(* Add `mbox_copy_spec_ref` to the hint database. Unfortunately, Coq will not unfold refinesFun
   and mbox_copy_spec when rewriting, and the only workaround I know right now is this :/ *)
Definition mbox_copy_spec_ref' : ltac:(let tp := type of mbox_copy_spec_ref in
                                       let tp' := eval unfold refinesFun, mbox_copy_spec, mbox_copy_spec_cons, empty_mbox_d in tp
                                        in exact tp') := mbox_copy_spec_ref.
Hint Rewrite mbox_copy_spec_ref' : refinement_proofs.
