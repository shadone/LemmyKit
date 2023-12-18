//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/utils/src/error.rs#L155
public enum LemmyServerError {
    case report_reason_required
    case report_too_long
    case not_a_moderator
    case not_an_admin
    case cant_block_yourself
    case cant_block_admin
    case couldnt_update_user
    case passwords_do_not_match
    case email_not_verified
    case email_required
    case couldnt_update_comment
    case couldnt_update_private_message
    case cannot_leave_admin
    case no_lines_in_html
    case site_metadata_page_is_not_doctype_html
    case pictrs_response_error(message: String)
    case pictrs_purge_response_error(message: String)
    case pictrs_caching_disabled
    case image_url_missing_path_segments
    case image_url_missing_last_path_segment
    case pictrs_api_key_not_provided
    case no_content_type_header
    case not_an_image_type
    case not_a_mod_or_admin
    case no_admins
    case not_top_admin
    case not_top_mod
    case not_logged_in
    case site_ban
    case deleted
    case banned_from_community
    case couldnt_find_community
    case couldnt_find_person
    case person_is_blocked
    case community_is_blocked
    case instance_is_blocked
    case downvotes_are_disabled
    case instance_is_private
    /// The specified password was not accepted by the Lemmy server.
    case invalid_password
    case site_description_length_overflow
    case honeypot_failed
    case registration_application_is_pending
    case cant_enable_private_instance_and_federation_together
    case locked
    case couldnt_create_comment
    case max_comment_depth_reached
    case no_comment_edit_allowed
    case only_admins_can_create_communities
    case community_already_exists
    case language_not_allowed
    case only_mods_can_post_in_community
    case couldnt_update_post
    case no_post_edit_allowed
    case couldnt_find_post
    case edit_private_message_not_allowed
    case site_already_exists
    case application_question_required
    case invalid_default_post_listing_type
    case registration_closed
    case registration_application_answer_required
    case email_already_exists
    case federation_forbidden_by_strict_allow_list
    case person_is_banned_from_community
    case object_is_not_public
    case invalid_community
    case cannot_create_post_or_comment_in_deleted_or_removed_community
    case cannot_receive_page
    case new_post_cannot_be_locked
    case only_local_admin_can_remove_community
    case only_local_admin_can_restore_community
    /// The required pameters were omitted, e.g. no user id to `/user` endpoint.
    case no_id_given
    /// The specified username/email or password was not accepted by the Lemmy server.
    case incorrect_login
    case invalid_query
    case object_not_local
    case post_is_locked
    case person_is_banned_from_site(message: String)
    case invalid_vote_value
    case page_does_not_specify_creator
    case page_does_not_specify_group
    case no_community_found_in_cc
    case no_email_setup
    case email_smtp_server_needs_a_port
    case missing_an_email
    case rate_limit_error
    case invalid_name
    case invalid_display_name
    case invalid_matrix_id
    case invalid_post_title
    case invalid_body_field
    case bio_length_overflow
    case missing_totp_token
    case missing_totp_secret
    case incorrect_totp_token
    case couldnt_parse_totp_secret
    case couldnt_generate_totp
    case totp_already_enabled
    case couldnt_like_comment
    case couldnt_save_comment
    case couldnt_create_report
    case couldnt_resolve_report
    case community_moderator_already_exists
    case community_user_already_banned
    case community_block_already_exists
    case community_follower_already_exists
    case couldnt_update_community_hidden_status
    case person_block_already_exists
    case user_already_exists
    case token_not_found
    case couldnt_like_post
    case couldnt_save_post
    case couldnt_mark_post_as_read
    case couldnt_update_community
    case couldnt_update_replies
    case couldnt_update_person_mentions
    case post_title_too_long
    case couldnt_create_post
    case couldnt_create_private_message
    case couldnt_update_private
    case system_err_login
    case couldnt_set_all_registrations_accepted
    case couldnt_set_all_email_verified
    case banned
    case couldnt_get_comments
    case couldnt_get_posts
    case invalid_url
    case email_send_failed
    case slurs
    case couldnt_find_object
    case registration_denied(message: String?)
    case federation_disabled
    case domain_blocked(message: String)
    case domain_not_in_allow_list(message: String)
    case federation_disabled_by_strict_allow_list
    case site_name_required
    case site_name_length_overflow
    case permissive_regex
    case invalid_regex
    case captcha_incorrect
    case password_reset_limit_reached
    case couldnt_create_audio_captcha
    case invalid_url_scheme
    case couldnt_send_webmention
    case contradicting_filters
    case instance_block_already_exists
    case too_many_items
    case community_has_no_followers
    case ban_expiration_in_past
    case invalid_unix_time
    case invalid_bot_action
    case cant_block_local_instance
    case unknown(message: String)

    public init(from errorResponse: ErrorResponse) {
        let errorCode = errorResponse.error

        switch errorCode {
        case "report_reason_required":
            self = .report_reason_required
        case "report_too_long":
            self = .report_too_long
        case "not_a_moderator":
            self = .not_a_moderator
        case "not_an_admin":
            self = .not_an_admin
        case "cant_block_yourself":
            self = .cant_block_yourself
        case "cant_block_admin":
            self = .cant_block_admin
        case "couldnt_update_user":
            self = .couldnt_update_user
        case "passwords_do_not_match":
            self = .passwords_do_not_match
        case "email_not_verified":
            self = .email_not_verified
        case "email_required":
            self = .email_required
        case "couldnt_update_comment":
            self = .couldnt_update_comment
        case "couldnt_update_private_message":
            self = .couldnt_update_private_message
        case "cannot_leave_admin":
            self = .cannot_leave_admin
        case "no_lines_in_html":
            self = .no_lines_in_html
        case "site_metadata_page_is_not_doctype_html":
            self = .site_metadata_page_is_not_doctype_html
        case "pictrs_response_error":
            self = .pictrs_response_error(message: errorResponse.message ?? "nil")
        case "pictrs_purge_response_error":
            self = .pictrs_purge_response_error(message: errorResponse.message ?? "nil")
        case "pictrs_caching_disabled":
            self = .pictrs_caching_disabled
        case "image_url_missing_path_segments":
            self = .image_url_missing_path_segments
        case "image_url_missing_last_path_segment":
            self = .image_url_missing_last_path_segment
        case "pictrs_api_key_not_provided":
            self = .pictrs_api_key_not_provided
        case "no_content_type_header":
            self = .no_content_type_header
        case "not_an_image_type":
            self = .not_an_image_type
        case "not_a_mod_or_admin":
            self = .not_a_mod_or_admin
        case "no_admins":
            self = .no_admins
        case "not_top_admin":
            self = .not_top_admin
        case "not_top_mod":
            self = .not_top_mod
        case "not_logged_in":
            self = .not_logged_in
        case "site_ban":
            self = .site_ban
        case "deleted":
            self = .deleted
        case "banned_from_community":
            self = .banned_from_community
        case "couldnt_find_community":
            self = .couldnt_find_community
        case "couldnt_find_person":
            self = .couldnt_find_person
        case "person_is_blocked":
            self = .person_is_blocked
        case "community_is_blocked":
            self = .community_is_blocked
        case "instance_is_blocked":
            self = .instance_is_blocked
        case "downvotes_are_disabled":
            self = .downvotes_are_disabled
        case "instance_is_private":
            self = .instance_is_private
        case "invalid_password":
            self = .invalid_password
        case "site_description_length_overflow":
            self = .site_description_length_overflow
        case "honeypot_failed":
            self = .honeypot_failed
        case "registration_application_is_pending":
            self = .registration_application_is_pending
        case "cant_enable_private_instance_and_federation_together":
            self = .cant_enable_private_instance_and_federation_together
        case "locked":
            self = .locked
        case "couldnt_create_comment":
            self = .couldnt_create_comment
        case "max_comment_depth_reached":
            self = .max_comment_depth_reached
        case "no_comment_edit_allowed":
            self = .no_comment_edit_allowed
        case "only_admins_can_create_communities":
            self = .only_admins_can_create_communities
        case "community_already_exists":
            self = .community_already_exists
        case "language_not_allowed":
            self = .language_not_allowed
        case "only_mods_can_post_in_community":
            self = .only_mods_can_post_in_community
        case "couldnt_update_post":
            self = .couldnt_update_post
        case "no_post_edit_allowed":
            self = .no_post_edit_allowed
        case "couldnt_find_post":
            self = .couldnt_find_post
        case "edit_private_message_not_allowed":
            self = .edit_private_message_not_allowed
        case "site_already_exists":
            self = .site_already_exists
        case "application_question_required":
            self = .application_question_required
        case "invalid_default_post_listing_type":
            self = .invalid_default_post_listing_type
        case "registration_closed":
            self = .registration_closed
        case "registration_application_answer_required":
            self = .registration_application_answer_required
        case "email_already_exists":
            self = .email_already_exists
        case "federation_forbidden_by_strict_allow_list":
            self = .federation_forbidden_by_strict_allow_list
        case "person_is_banned_from_community":
            self = .person_is_banned_from_community
        case "object_is_not_public":
            self = .object_is_not_public
        case "invalid_community":
            self = .invalid_community
        case "cannot_create_post_or_comment_in_deleted_or_removed_community":
            self = .cannot_create_post_or_comment_in_deleted_or_removed_community
        case "cannot_receive_page":
            self = .cannot_receive_page
        case "new_post_cannot_be_locked":
            self = .new_post_cannot_be_locked
        case "only_local_admin_can_remove_community":
            self = .only_local_admin_can_remove_community
        case "only_local_admin_can_restore_community":
            self = .only_local_admin_can_restore_community
        case "no_id_given":
            self = .no_id_given
        case "incorrect_login":
            self = .incorrect_login
        case "invalid_query":
            self = .invalid_query
        case "object_not_local":
            self = .object_not_local
        case "post_is_locked":
            self = .post_is_locked
        case "person_is_banned_from_site":
            self = .person_is_banned_from_site(message: errorResponse.message ?? "nil")
        case "invalid_vote_value":
            self = .invalid_vote_value
        case "page_does_not_specify_creator":
            self = .page_does_not_specify_creator
        case "page_does_not_specify_group":
            self = .page_does_not_specify_group
        case "no_community_found_in_cc":
            self = .no_community_found_in_cc
        case "no_email_setup":
            self = .no_email_setup
        case "email_smtp_server_needs_a_port":
            self = .email_smtp_server_needs_a_port
        case "missing_an_email":
            self = .missing_an_email
        case "rate_limit_error":
            self = .rate_limit_error
        case "invalid_name":
            self = .invalid_name
        case "invalid_display_name":
            self = .invalid_display_name
        case "invalid_matrix_id":
            self = .invalid_matrix_id
        case "invalid_post_title":
            self = .invalid_post_title
        case "invalid_body_field":
            self = .invalid_body_field
        case "bio_length_overflow":
            self = .bio_length_overflow
        case "missing_totp_token":
            self = .missing_totp_token
        case "missing_totp_secret":
            self = .missing_totp_secret
        case "incorrect_totp_token":
            self = .incorrect_totp_token
        case "couldnt_parse_totp_secret":
            self = .couldnt_parse_totp_secret
        case "couldnt_generate_totp":
            self = .couldnt_generate_totp
        case "totp_already_enabled":
            self = .totp_already_enabled
        case "couldnt_like_comment":
            self = .couldnt_like_comment
        case "couldnt_save_comment":
            self = .couldnt_save_comment
        case "couldnt_create_report":
            self = .couldnt_create_report
        case "couldnt_resolve_report":
            self = .couldnt_resolve_report
        case "community_moderator_already_exists":
            self = .community_moderator_already_exists
        case "community_user_already_banned":
            self = .community_user_already_banned
        case "community_block_already_exists":
            self = .community_block_already_exists
        case "community_follower_already_exists":
            self = .community_follower_already_exists
        case "couldnt_update_community_hidden_status":
            self = .couldnt_update_community_hidden_status
        case "person_block_already_exists":
            self = .person_block_already_exists
        case "user_already_exists":
            self = .user_already_exists
        case "token_not_found":
            self = .token_not_found
        case "couldnt_like_post":
            self = .couldnt_like_post
        case "couldnt_save_post":
            self = .couldnt_save_post
        case "couldnt_mark_post_as_read":
            self = .couldnt_mark_post_as_read
        case "couldnt_update_community":
            self = .couldnt_update_community
        case "couldnt_update_replies":
            self = .couldnt_update_replies
        case "couldnt_update_person_mentions":
            self = .couldnt_update_person_mentions
        case "post_title_too_long":
            self = .post_title_too_long
        case "couldnt_create_post":
            self = .couldnt_create_post
        case "couldnt_create_private_message":
            self = .couldnt_create_private_message
        case "couldnt_update_private":
            self = .couldnt_update_private
        case "system_err_login":
            self = .system_err_login
        case "couldnt_set_all_registrations_accepted":
            self = .couldnt_set_all_registrations_accepted
        case "couldnt_set_all_email_verified":
            self = .couldnt_set_all_email_verified
        case "banned":
            self = .banned
        case "couldnt_get_comments":
            self = .couldnt_get_comments
        case "couldnt_get_posts":
            self = .couldnt_get_posts
        case "invalid_url":
            self = .invalid_url
        case "email_send_failed":
            self = .email_send_failed
        case "slurs":
            self = .slurs
        case "couldnt_find_object":
            self = .couldnt_find_object
        case "registration_denied":
            self = .registration_denied(message: errorResponse.message)
        case "federation_disabled":
            self = .federation_disabled
        case "domain_blocked":
            self = .domain_blocked(message: errorResponse.message ?? "nil")
        case "domain_not_in_allow_list":
            self = .domain_not_in_allow_list(message: errorResponse.message ?? "nil")
        case "federation_disabled_by_strict_allow_list":
            self = .federation_disabled_by_strict_allow_list
        case "site_name_required":
            self = .site_name_required
        case "site_name_length_overflow":
            self = .site_name_length_overflow
        case "permissive_regex":
            self = .permissive_regex
        case "invalid_regex":
            self = .invalid_regex
        case "captcha_incorrect":
            self = .captcha_incorrect
        case "password_reset_limit_reached":
            self = .password_reset_limit_reached
        case "couldnt_create_audio_captcha":
            self = .couldnt_create_audio_captcha
        case "invalid_url_scheme":
            self = .invalid_url_scheme
        case "couldnt_send_webmention":
            self = .couldnt_send_webmention
        case "contradicting_filters":
            self = .contradicting_filters
        case "instance_block_already_exists":
            self = .instance_block_already_exists
        case "too_many_items":
            self = .too_many_items
        case "community_has_no_followers":
            self = .community_has_no_followers
        case "ban_expiration_in_past":
            self = .ban_expiration_in_past
        case "invalid_unix_time":
            self = .invalid_unix_time
        case "invalid_bot_action":
            self = .invalid_bot_action
        case "cant_block_local_instance":
            self = .cant_block_local_instance
        case "unknown":
            self = .unknown(message: errorResponse.message ?? "nil")

        default:
            self = .unknown(message: "\(errorCode); message=\(errorResponse.message ?? "nil")")
        }
    }
}
