/datum/website/forums
	title = "Unnamed Forum"

	var/list/datum/forum_member/members
	var/list/datum/forum_thread/threads
	var/list/banned_members
	var/list/admins

	var/audit_log

	var/list/available_categories = list("General", "Admin Only")
	var/list/admin_only_categories = list("Admin Only")

	var/show_edits

	var/forum_description = "This is a generic forum."
	var/open_registration = TRUE				// This forum open to registration?

	interactive_website = "forum"


/datum/forum_member
	var/username = ""
	var/password = ""
	var/email
	var/uid

//	var/avatars								//I guess photos can be used? In future, maybe?
	var/banned = FALSE						// Whether the account is banned by the admins.

	var/member_ckey							// So actual admins can keep track of things.

/datum/forum_post
	var/id

	var/title
	var/content
	var/author

	var/post_ckey							// So actual admins can keep track of things.
	var/datum/forum_thread/host_thread
	var/edited

/datum/forum_thread
	var/id

	var/title
	var/list/datum/forum_post/posts
	var/author								// The OP
	var/locked = FALSE						// Admins can lock threads
	var/category = "General"
	var/datum/website/forums/host_forum

/datum/website/forums/proc/register_new_member(username, password, email, uid, member_ckey)
	var/datum/forum_member/M = new()
	M.username = username
	M.password = password
	M.email = email
	M.uid = uid
	M.member_ckey = member_ckey



	return M

// Forum Audit Log (Persistent log that shows all actions on a forum.
/datum/website/forums/proc/add_audit_log(msg)
	msg = copytext(msg, 1, MAX_MESSAGE_LEN)

	msg = sanitize(msg)

	if (length(msg) == 0)
		audit_log += msg
	else
		audit_log += "<BR>[msg]"
// Forum Procs

/datum/website/forums/proc/make_category(category, datum/forum_member/admin)		// returns the full audit log all of moderation actions happening
	if(category in available_categories)
		return 0

	if(admin)
		add_audit_log("<b>[admin]</b> made a new category <b>\"[category]\"</b> - [stationtime2text()]")

	available_categories += category

	return 1


/datum/website/forums/proc/remove_category(category, datum/forum_member/admin)		// returns the full audit log all of moderation actions happening
	if(admin)
		add_audit_log("<b>[admin]</b> removed category <b>\"[category]\"</b> - [stationtime2text()]")

	available_categories -= category
	admin_only_categories -= category

/datum/website/forums/proc/edit_category(category, new_category, datum/forum_member/admin)		// returns the full audit log all of moderation actions happening
	if(admin)
		add_audit_log("<b>[admin]</b> edited category <b>\"[new_category]\"</b> - [stationtime2text()]")

	for(var/datum/forum_post/P in get_posts())
		if(category == P.host_thread.category)
			P.host_thread.category = new_category

	available_categories -= category
	admin_only_categories -= category

	available_categories += new_category
	admin_only_categories += new_category

//counters
/datum/website/forums/proc/get_audit_log()		// returns the full audit log all of moderation actions happening
	if(!audit_log)
		return "No logs found."
	return audit_log

/datum/website/forums/proc/member_count()		// returns how many members
	if(!members)
		return 0
	return members.len

/datum/website/forums/proc/admins_count()		// returns how many admins
	if(!admins)
		return 0
	return admins.len

/datum/website/forums/proc/thread_count()		// returns how many threads in the entire forum
	if(!threads)
		return 0
	return threads.len

/datum/website/forums/proc/get_posts()
	var/all_posts
	for(var/datum/forum_thread/T in threads)
		all_posts += T.posts

	return all_posts


/datum/website/forums/proc/get_threads_by_cat(category)
	var/tally_posts
	for(var/datum/forum_thread/T in get_posts())
		if(T.category == category)
			tally_posts += T

	return tally_posts



/datum/website/forums/proc/get_cat_thread_count(category)
	var/list/total_threads = get_threads_by_cat(category)
	return total_threads.len


/datum/website/forums/proc/post_count()			// returns how many posts in the entire forum
	var/list/full_posts = get_posts()

	return full_posts.len

// Member related procs

/datum/website/forums/proc/ban_member(datum/forum_member/M, datum/forum_member/admin)
	if(M)
		add_audit_log("<b>[M.username]</b> was banned from [title] by [admin] - [stationtime2text()]")

	M.banned = TRUE
	return 1

/datum/website/forums/proc/unban_member(datum/forum_member/M, datum/forum_member/admin)
	if(M)
		add_audit_log("<b>[M.username]</b> was unbanned from [title] by [admin] - [stationtime2text()]")
	M.banned = FALSE
	return 1

/datum/website/forums/proc/delete_member(datum/forum_member/M, datum/forum_member/admin)
	if(M)
		add_audit_log("<b>[M.username]</b> account deleted by [admin] - [stationtime2text()]")
	if(qdel(M))
		return 1

/datum/website/forums/proc/make_admin(datum/forum_member/M, datum/forum_member/admin)
	if(M)
		add_audit_log("<b>[M.username]</b> was made an admin by [admin] - [stationtime2text()]")
	admins += M
	return 1

/datum/website/forums/proc/remove_admin(datum/forum_member/M, datum/forum_member/admin)
	if(M)
		add_audit_log("<b>[M.username]</b> was removed from admin by [admin] - [stationtime2text()]")
	admins -= M
	return 1

/datum/website/forums/proc/get_post_count(datum/forum_member/M)
	var/postcount
	for(var/datum/forum_post/P in get_posts())
		if(P.author == M)
			postcount++

	return postcount

//Thread related procs

/datum/website/forums/proc/create_thread(datum/forum_member/M, category, thread_title, content)
	var/datum/forum_post/P = new()
	var/datum/forum_thread/T = new()

	// set the thread

	T.title = thread_title
	T.author = M
	T.category = category
	T.host_forum = src

	// set the post

	P.title = thread_title
	P.content = content
	P.author = M
	P.post_ckey = M.member_ckey

	// Add post to the the thread and vice versa.

	T.posts += P
	P.host_thread = T

	if(M)
		add_audit_log("<b>[M.username]</b> created the thread <b>\"[T.title]\"</b> - [stationtime2text()]")


/datum/forum_thread/proc/get_posts()
	return posts

/datum/website/forums/proc/delete_thread(datum/forum_thread/T, datum/forum_member/M)
	if(M)
		add_audit_log("<b>[M.username]</b> deleted the thread <b>\"[T.title]\"</b> - [stationtime2text()]")

	qdel(T.get_posts())
	qdel(T)



/datum/website/forums/proc/move_thread(datum/forum_thread/T, new_category, datum/forum_member/admin)
	if(admin)
		add_audit_log("<b>[admin.username]</b> moved the thread <b>\"[T.title]\"</b> from [T.category] to [new_category] - [stationtime2text()]")

	T.category = new_category



/datum/website/forums/proc/lock_thread(datum/forum_thread/T, datum/forum_member/admin)
	if(admin)
		add_audit_log("<b>[admin.username]</b> locked the thread <b>\"[T.title]\"</b> - [stationtime2text()]")

	T.locked = 1


//Post related procs

/datum/forum_thread/proc/new_post(datum/forum_member/M, post_title, content)
	var/datum/forum_post/P = new()

	P.title = post_title
	P.content = content
	P.author = M
	P.post_ckey = M.member_ckey


	// Add post to the the thread and vice versa.

	posts += P
	P.host_thread = src


/datum/forum_thread/proc/delete_post(datum/forum_post/deleted_post, datum/forum_member/M)
	if(M)
		host_forum.add_audit_log("<b>[M.username]</b> deleted the post <b>\"[deleted_post.title]\"</b> - [stationtime2text()]")

	posts -= deleted_post
	qdel(deleted_post)

/datum/forum_thread/proc/edit_post(datum/forum_post/edited_post, new_content, datum/forum_member/M)
	if(M)
		host_forum.add_audit_log("<b>[M.username]</b> edited the post <b>\"[edited_post.title]\"</b> - [stationtime2text()]")

	edited_post.content = new_content
	if(host_forum && host_forum.show_edits)
		edited_post.edited = TRUE


// Registration

/datum/website/forums/proc/register_new_account(mob/user)
	if(!open_registration)
		return 0

	var/username = sanitize(input(usr, "Please enter a username.", "username", null)  as text)
	if(!username)
		return 0

	var/email = sanitize(input(usr, "Please enter an email.", "email", null)  as text)
	if(!email)
		return 0

	var/password = sanitize(input(usr, "Please enter a password.", "password", null)  as text)
	if(!password)
		return 0