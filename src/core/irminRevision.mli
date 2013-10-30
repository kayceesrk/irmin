(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(** Manage the database history. *)

type ('a, 'b) node = {
  tree   : 'a option;
  parents: 'b list;
}
(** Type of concrete revisions. *)

type ('a, 'b) store = {
  t: 'a;
  r: 'b;
}
(** Type of concrete stores. *)

module type STORE = sig

  (** The database history is a partial-order of revisions. *)

  type key
  (** Type of keys. *)

  type tree
  (** Type of trees. *)

  type revision = (key, key) node
  (** Type of revisions. *)

  include IrminBase.S with type t := revision
  (** Revisions are base types. *)

  module Graph: IrminGraph.S with type Vertex.t = revision
  (** Graph of revisions. *)

  include IrminStore.A with type key := key
                        and type value := revision
  (** Revision stores are immutable. *)

  val revision: t -> ?tree:tree -> revision list -> key Lwt.t
  (** Create a new revision. *)

  val tree: t -> revision -> tree Lwt.t option
  (** Get the revision tree. *)

  val parents: t -> revision -> revision Lwt.t list
  (** Get the immmediate precessors. *)

  val cut: t -> ?roots:key list -> key list -> Graph.t Lwt.t
  (** [cut t max] returns a consistent cut of the global partial
      order, where [max] are the max elements of the cut. If [roots]
      is set, these are the only minimal elements taken into
      account. *)

end

module Make
    (S: IrminStore.A_RAW)
    (K: IrminKey.S with type t = S.key)
    (T: IrminTree.STORE with type key = S.key)
  : STORE with type t = (T.t, S.t) store
           and type key = T.key
           and type tree = T.tree
(** Create a revision store. *)