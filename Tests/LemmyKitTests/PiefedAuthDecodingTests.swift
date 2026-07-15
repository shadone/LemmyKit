//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import Testing
@testable import LemmyKit

/// Decodes hand-captured live PieFed `/api/alpha` auth/write/inbox fixtures (PieFed 1.7.5,
/// self-hosted `piefed1.lemmy.ddenis.info`, 2026-07-15) into the hand-written `Piefed*` auth/write
/// models. Like ``PiefedDecodingTests`` this is a pure wire-decode test -- no adapters, no neutral
/// DTOs -- proving the models match PieFed's actual authed JSON shape. Assertions are pinned to
/// captured values, so a genuine field-name mismatch fails loudly instead of silently passing.
///
/// Fixture provenance (all captured against the self-hosted validation instance with the `mark`
/// test account, person id 10; NO secrets are present -- captures were grepped for `eyJ`-prefixed
/// JWTs and the account password before staging):
/// - `piefed-login.json` -- SYNTHESIZED `{"jwt": "fixture.jwt.value"}`; a real login response is
///   NEVER captured (it carries a live JWT).
/// - `piefed-success.json` -- SYNTHESIZED `{"success": true}` (the bare shape `post/mark_as_read`
///   returns).
/// - `piefed-user_me.json` -- `GET /api/alpha/user/me` (authed). NOTE: this route's `follows` array
///   is EMPTY even while the account is subscribed to a community -- a PieFed quirk; the populated
///   follow list rides the `GET /api/alpha/site` `my_user` embed instead (see below).
/// - `piefed-site_authed.json` -- `GET /api/alpha/site` (authed); carries the `my_user` embed whose
///   shape is byte-for-byte the `user/me` response, and whose `follows` DOES reflect the live
///   subscription (community `piefedtest`, captured while transiently subscribed, then restored).
/// - `piefed-unread_count.json` -- `GET /api/alpha/user/unread_count`.
/// - `piefed-post_response.json` -- response of `POST /api/alpha/post/like {"post_id":13,"score":1}`
///   (the vote was restored to `score:0` afterward). Bare `{post_view}` wrapper.
/// - `piefed-comment_response.json` -- response of `POST /api/alpha/comment
///   {"body":"Spud fixture capture - will be deleted","post_id":13}` (the comment, id 7, was deleted
///   afterward). Bare `{comment_view}` wrapper; the author's own comment is auto-upvoted.
/// - `piefed-community_follow.json` -- response of `POST /api/alpha/community/follow
///   {"community_id":1,"follow":true}` (restored to `follow:false` afterward).
/// - `piefed-pm_list.json` -- `GET /api/alpha/private_message/list` (empty on this instance -- it
///   pins the `private_messages` wrapper key).
/// - `piefed-replies.json` -- `GET /api/alpha/user/replies` (empty inbox -- pins the `replies`
///   wrapper + nullable `next_page`).
/// - `piefed-person_details.json` -- `GET /api/alpha/user?person_id=10&include_content=true` (the
///   person-details route; schema `GetUserResponse` in the vendored `piefed-alpha-spec.json`).
///   Captured for the test account's own person id (from `user/me`).
/// - `piefed-pm_view.json` -- SYNTHETIC, built from the vendored spec's `PrivateMessageView` schema
///   (`private_message{id,creator_id,recipient_id,content,deleted,read,published,ap_id,local}`,
///   `creator`, `recipient`, `conversation_id`) because the live PM list is empty. The `creator`
///   (`admin`) and `recipient` (`mark`) person objects are copied verbatim from real captures; only
///   the `private_message` envelope is fabricated. Re-validated live in Task 9.
/// - `piefed-replies_item.json` -- SYNTHETIC, built from the vendored spec's `CommentReplyView`
///   schema because the live replies inbox is empty. The `comment`/`counts` sub-objects are copied
///   from `piefed-comment_response.json`, `community`/`post` from `piefed-post_response.json`, and
///   the `creator`/`recipient` persons from real captures; only the `comment_reply` envelope is
///   fabricated. Re-validated live in Task 9.
struct PiefedAuthDecodingTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    private var decoder: JSONDecoder { JSONDecoder() }

    @Test
    func decodesLogin() throws {
        let resp = try decoder.decode(PiefedLoginResponse.self, from: fixture("piefed-login"))
        #expect(resp.jwt == "fixture.jwt.value")
    }

    @Test
    func decodesSuccess() throws {
        let resp = try decoder.decode(PiefedSuccessResponse.self, from: fixture("piefed-success"))
        #expect(resp.success == true)
    }

    @Test
    func decodesUserMe() throws {
        let resp = try decoder.decode(PiefedUserMeResponse.self, from: fixture("piefed-user_me"))
        #expect(resp.local_user_view.person.user_name == "mark")
        #expect(resp.local_user_view.person.id == 10)
        #expect(resp.local_user_view.counts.person_id == 10)
        // `user/me` reports the account's saved settings on `local_user`; pin one to prove the shape.
        #expect(resp.local_user_view.local_user.default_sort_type == "Hot")
        // The `user/me` `follows` array is empty here even while subscribed -- the populated follow
        // list rides the `site` `my_user` embed instead (see `decodesSiteAuthed`).
        #expect(resp.follows.isEmpty)
        #expect(resp.moderates.isEmpty)
    }

    @Test
    func decodesSiteAuthed() throws {
        let resp = try decoder.decode(PiefedGetSiteResponse.self, from: fixture("piefed-site_authed"))
        let myUser = try #require(resp.my_user, "authed /site must carry the my_user embed")
        #expect(myUser.local_user_view.person.user_name == "mark")
        // Unlike `user/me`, the `my_user` embed's `follows` reflects the live subscription.
        #expect(myUser.follows.count == 1)
        #expect(myUser.follows.first?.community.name == "piefedtest")
        #expect(resp.site.name.isEmpty == false)
        #expect(resp.version.isEmpty == false)
    }

    @Test
    func decodesUnreadCount() throws {
        let resp = try decoder.decode(PiefedUnreadCountResponse.self, from: fixture("piefed-unread_count"))
        #expect(resp.mentions == 0)
        #expect(resp.replies == 0)
        #expect(resp.private_messages == 0)
        #expect(resp.other == 0)
    }

    @Test
    func decodesPostResponse() throws {
        let resp = try decoder.decode(PiefedPostResponse.self, from: fixture("piefed-post_response"))
        #expect(resp.post_view.my_vote == 1)
        #expect(resp.post_view.counts.score == 2)
        #expect(resp.post_view.post.id == 13)
    }

    @Test
    func decodesCommentResponse() throws {
        let resp = try decoder.decode(PiefedCommentResponse.self, from: fixture("piefed-comment_response"))
        #expect(resp.comment_view.comment.body == "Spud fixture capture - will be deleted")
        #expect(resp.comment_view.comment.id == 7)
        // Author's own comment is auto-upvoted on creation.
        #expect(resp.comment_view.my_vote == 1)
    }

    @Test
    func decodesCommunityFollow() throws {
        let resp = try decoder.decode(PiefedCommunityFollowResponse.self, from: fixture("piefed-community_follow"))
        #expect(resp.community_view.subscribed == "Subscribed")
        #expect(resp.community_view.community.id == 1)
        #expect(resp.community_view.community.name == "piefedtest")
    }

    @Test
    func decodesPrivateMessageList() throws {
        let resp = try decoder.decode(PiefedPrivateMessageListResponse.self, from: fixture("piefed-pm_list"))
        #expect(resp.private_messages.isEmpty)
    }

    @Test
    func decodesPrivateMessageView() throws {
        let view = try decoder.decode(PiefedPrivateMessageView.self, from: fixture("piefed-pm_view"))
        #expect(view.private_message.content == "Synthetic DM body for fixture decoding")
        #expect(view.private_message.recipient_id == 10)
        #expect(view.creator.user_name == "admin")
        #expect(view.recipient.user_name == "mark")
        #expect(view.conversation_id == 1)
    }

    @Test
    func decodesReplies() throws {
        let resp = try decoder.decode(PiefedRepliesResponse.self, from: fixture("piefed-replies"))
        #expect(resp.replies.isEmpty)
        #expect(resp.next_page == nil)
    }

    @Test
    func decodesReplyItem() throws {
        let item = try decoder.decode(PiefedReplyItem.self, from: fixture("piefed-replies_item"))
        #expect(item.comment.body == "Spud fixture capture - will be deleted")
        #expect(item.comment_reply.id == 1)
        #expect(item.comment_reply.read == false)
        #expect(item.creator.user_name == "admin")
        #expect(item.community.name == "piefedtest")
    }

    @Test
    func decodesPersonDetails() throws {
        let resp = try decoder.decode(PiefedPersonDetailsResponse.self, from: fixture("piefed-person_details"))
        #expect(resp.person_view.person.user_name == "mark")
        #expect(resp.person_view.person.id == 10)
        #expect(resp.comments.count == 1)
        #expect(resp.posts.isEmpty)
    }
}
