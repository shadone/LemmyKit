//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import Testing
@testable import LemmyKit

/// Decodes hand-captured live PieFed `/api/alpha` fixtures (PieFed 1.7.5, `piefed.social`,
/// 2026-07-15) into the hand-written `Piefed*` models. This is a pure wire-decode test -- no
/// adapters, no neutral DTOs -- proving the models match PieFed's actual JSON shape. Assertions
/// on specific values are pinned to the captured fixtures (not tautological placeholders), so
/// a genuine field-name mismatch fails loudly instead of silently passing.
struct PiefedDecodingTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    private var decoder: JSONDecoder { JSONDecoder() }

    @Test
    func decodesPostList() throws {
        let resp = try decoder.decode(PiefedGetPostsResponse.self, from: fixture("piefed-post_list"))
        #expect(resp.posts.count == 3)

        let view = try #require(resp.posts.first)
        #expect(view.post.id == 2_210_778)
        #expect(view.post.title == "'Man of Tomorrow': Xolo Maridueña to Return as Blue Beetle in James Gunn's Sequel")
        #expect(view.post.user_id == 176_409)
        #expect(view.post.community_id == 2615)
        #expect(view.post.ap_id.hasPrefix("https://piefed.social/c/movies"))
        #expect(view.post.sticky == false)
        #expect(view.post.instance_sticky == false)
        #expect(view.post.post_type == "Link")
        #expect(view.post.url == "https://www.thewrap.com/creative-content/movies/man-of-tomorrow-blue-beetle-xolo-mariduena/")
        #expect(view.post.body == nil)
        #expect(view.post.image_details?.width == 512)
        #expect(view.post.image_details?.height == 288)
        #expect(view.post.cross_posts?.first?.community_name == "DC Studios")

        #expect(view.creator.user_name == "TheImpressiveX")
        #expect(view.creator.id == 176_409)
        #expect(view.creator.bot == false)

        #expect(view.community.name == "movies")
        #expect(view.community.restricted_to_mods == false)
        #expect(view.community.banner == nil) // lightweight embedded shape, not the rich profile
        #expect(view.community.updated != nil)

        #expect(view.counts.comments == 0)
        #expect(view.counts.post_id == 2_210_778)

        #expect(view.subscribed == "NotSubscribed" || view.subscribed == "Subscribed" || view.subscribed == "Pending")
        #expect(view.my_vote == 0)
        #expect(view.banned_from_community == false)
        #expect(view.creator_blocked == nil) // absent when signed out

        // Second post in the fixture carries a body (unlike the first) -- proves `body` decodes
        // when present, not just that it tolerates absence.
        let secondPost = resp.posts[1].post
        #expect(secondPost.body?.contains("Featured Screenshot by Yummy") == true)
    }

    @Test
    func decodesCommentList() throws {
        let resp = try decoder.decode(PiefedGetCommentsResponse.self, from: fixture("piefed-comment_list"))
        #expect(resp.comments.count == 10)

        let view = try #require(resp.comments.first)
        #expect(view.comment.id == 12_115_800)
        #expect(view.comment.body == "Keep making live action movies nobody wants. Do it over and over again. ")
        #expect(view.comment.user_id == 225_220)
        #expect(view.comment.post_id == 2_210_082)
        #expect(view.comment.path == "0.12115800")
        #expect(view.comment.repliesEnabled == true)
        #expect(view.comment.answer == false)

        #expect(view.creator.user_name == "thethrilloftime69")
        #expect(view.post.id == 2_210_082)
        #expect(view.community.name == "movies")

        #expect(view.counts.comment_id == 12_115_800)
        #expect(view.counts.score == 42)

        #expect(view.banned_from_community == false)
        #expect(view.creator_blocked == false)
        #expect(view.my_vote == 0)
    }

    @Test
    func decodesCommunityList() throws {
        let resp = try decoder.decode(PiefedListCommunitiesResponse.self, from: fixture("piefed-community_list"))
        #expect(resp.communities.count == 3)

        let view = try #require(resp.communities.first)
        #expect(view.community.name == "microblogs")
        #expect(view.community.title == "Microblogs")
        #expect(view.community.id == 15339)
        #expect(view.community.restricted_to_mods == false)
        // Not present at all on this wire shape (verified against the live payload) --
        // decodes to nil the same way it would if PieFed sent an explicit `null`.
        #expect(view.banned_from_community == nil)
        #expect(view.subscribed == "NotSubscribed")

        #expect(view.counts.post_count > 0)
    }

    @Test
    func decodesPostDetail() throws {
        let resp = try decoder.decode(PiefedGetPostResponse.self, from: fixture("piefed-post_detail"))
        #expect(resp.post_view.post.id == 2_210_778)
        #expect(resp.post_view.post.title.contains("Man of Tomorrow"))

        #expect(resp.community_view.community.name == "movies")
        #expect(resp.community_view.community.banner != nil) // rich shape: banner present here
        #expect(resp.community_view.community.description != nil)

        #expect(resp.moderators.count == 4)
        #expect(resp.moderators.first?.moderator.user_name == "atomicpoet")
        #expect(resp.moderators.first?.community.name == "movies")

        #expect(resp.cross_posts.count == 1)
        #expect(resp.cross_posts.first?.community.name == "dcstudios")
        #expect(resp.cross_posts.first?.community.local == false)
    }

    @Test
    func decodesSite() throws {
        let resp = try decoder.decode(PiefedGetSiteResponse.self, from: fixture("piefed-site"))
        #expect(resp.version == "1.7.5")
        #expect(resp.site.name == "PieFed")
        #expect(resp.site.registration_mode == "RequireApplication")
        #expect(resp.site.all_languages.count == 193)
        #expect(resp.admins.count == 6)

        let firstAdmin = try #require(resp.admins.first)
        #expect(firstAdmin.person.user_name == "rimu")
        #expect(firstAdmin.is_admin == true)
        #expect(firstAdmin.counts.post_count == 912)
    }

    @Test
    func decodesSearch() throws {
        let resp = try decoder.decode(PiefedSearchResponse.self, from: fixture("piefed-search"))
        #expect(resp.type_ == "Communities")
        #expect(resp.communities.count == 3)
        #expect(resp.posts.isEmpty)
        #expect(resp.comments.isEmpty)
        #expect(resp.users.isEmpty)

        let firstCommunity = try #require(resp.communities.first)
        #expect(firstCommunity.community.name == "technology")
        #expect(firstCommunity.community.actor_id == "https://lemmy.world/c/technology")
    }

    @Test
    func decodesErrorEnvelope() throws {
        let data = Data(#"{"code":400,"message":"incorrect_login","status":"Bad Request"}"#.utf8)
        let err = try decoder.decode(PiefedErrorBody.self, from: data)
        #expect(err.code == 400)
        #expect(err.message == "incorrect_login")
        #expect(err.status == "Bad Request")
    }
}
