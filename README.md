# thwart

A simple, powerful, and developer friendly authorization gem.

## What thwart is for

thwart was designed to prohibit access to resources by system actors based on a predefined set of rules, or in other words, only let people see the stuff they should be able to. When coupled with a slick DSL for defining the rules and unparalleled ease of set up, thwart provides a simple way to get very complex authorization behaviour in your system quickly. It was designed with Rails in mind and has handy integration hooks for Rails 3, but should work in plenty of other situations. 

## How thwart works

thwart works like many other permissions systems out there, and draws from Canable & Cancan, Declarative Authorization, Zend_ACL, and acl9. It is an RBAC (Role Based Access Control) style system, which means the developer defines roles which actors then play and become governed by the role's rules. By throwing in role inheritance and runtime assertions, quite advanced permissions logic can be defined in a simple and easily editable way.

Setting up thwart goes something like this:

 1.	Figure out what objects/classes of objects you are trying to prevent/grant access to. Call these _resources_.
 2. Figure out who (again, objects/classes) should have limited access to the resources. Call these _actors_.
 3. Figure out what different operations can be done on resources by actors. Call these _actions_. Optionally you can group similar actions into _action groups_.
 4. Figure out what sets of actions on each resource can or can't be taken by all the kinds of actors. Call each _action_/_actor_/_resource_ combination a _rule_.
 5. Factor all the rules out into groups called _roles_ which actors then act as, becoming subject to the set of rules.
 6. Enforce access to resources throughout your system using thwart _enforcers_.

### An Example

	Thwart.configure do

		# Declare 3 actions
		action {:view => :viewable, :update => :updatable, :destroy => :destroyable}
		
		# Declare the role :employee
		role :employee do
			view :all				# Grant view permission on all resources
			update :this, :that		# Grant update permission on resources of type :this or :that
		end
	end

Above thwart is being configured to have two actions, `view` and `update`, and one role named `employee`. If an actor (which we'll see how to set up in a minute) were to play the `employee` role, they would be able to view any and all resources, and update resources of type `this` or `that`. Otherwise, thwart will by default respond false to any queries. See 'Integrating thwart with your objects' to know how the 'type' of the resource can specified. 

Also, notice that actions must be explicitly declared to exist, which is the call to `action` above
### Querying Thwart

To actually run queries and enforce the rules defined in thwart, you must check if an actor is able to preform an action on a resource before executing the code that corresponds to that action. Thwart allows you to do this in a very easy way, pioneered by John Nunemaker of Canable fame. Pretending we have an actor playing the `:employee` role in `@employee_actor` and an instance of the `This` class is `@this_instance`, read this example:

	@employee_actor.can_view?(:this) 				# => true
	@employee_actor.can_update?(:this) 				# => true
	@employee_actor.can_destroy?(:this) 			# => false
	
	@this_instance.viewable_by?(@employee_actor) 	# => true
	@this_instance.destroyable_by?(@employee_actor) # => false

You can also run straight up queries with the associated objects using `Thwart.query`. Notice also this method allows you to pass in the thwart name of the object instead of an instance for the resource parameter, effectively checking if the actor can `:update` any and all instances of `This`.

	Thwart.query(@employee_actor, @this_instance, :view)  	# => true
	Thwart.query(@employee_actor, @this_instance, :destroy) # => false
	Thwart.query(@employee_actor, @this_instance, :update)  # => true
	Thwart.query(@employee_actor, :this, :update) 			# => true

# Integrating thwart with your objects

Integrating thwart with the objects that need protection and need their access filtered isn't too hard. All that needs to be done is to include the appropriate thwart module and then call `thwart_access` on the class. Thwart just needs to be able to figure out the name of the resource or the role of the actor, and you can hard code this or tell thwart where to look by passing configuration to the `thwart_access` method.

For resources, include the `Thwart::Resource` module and call `thwart_access`, optionally passing it a configuration block.

	class Post
		include Thwart::Resource
		thwart_access do
			# All configuration options are passed here. Only one is present for resources:
			
			# the thwart name of this object for use in referencing it in the configuration. 
			# This is automatically determined by lowercasing the class name, but can be manually 
			# specified here by passing a symbol.
			name :post  

		end
	end

For actors, include the `Thwart::Actor` module and call `thwart_access`, passing it a configuration block detailing how to find the actor's role. 

	class User
		include Thwart::Actor
		thwart_access do
			# All configuration options are passed here.
			
			# The name of the role that should be played by default by all instances of 
			# this class. Note that this can be overridden on an instance by instance
			# basis by the two configuration options below.
			role :employee
			
			# Optional: a method to call on the instance to find the instance's role.
			# This could be a simple attribute stored in the database
			role_method :an_instance_method
			
			# Optional: a proc to call which should return the role which this
			# instance should play.
			role_proc Proc.new do 
				# some work to find the role
				:some_role_to_play
			end
			
		end
	end

If an object is both an actor and a resource (for example, a user which should only be able to edit it's own profile information), just call `thwart_access` after including each module like so:

	class User
		include Thwart::Actor
		thwart_access
		include Thwart::Resource
		thwart_access
	end

## Complex Rule Definition

	Thwart.configure do
		# Add :create, :show, :update, and :destroy
		Thwart::Actions.add_crud!
		# Set the default response
		default_query_response false

		action_group :manage, [:view, :create, :update, :destroy]

		role :employee do
			view :all
			update :this, :that
		end

		role :manager, :include => :employee do
			allow do
				create :those, :if => Proc.new do |actor, resource, role|
					return true if actor.id == resource.created_by
				end
				destroy :this
			end
			deny do
				destroy :that
			end
		end

		role :administrator do
			manage :all
		end
	end
	
#### Add Crud

The above example showcases all the features of the rule definition DSL. At the top, a special helper method is called to add the default CRUD actions as used in Rails, which are `:create`, `:show`, `:update`, and `:destroy`. 

#### Default Response

To illustrate setting the default response, a call to that also appears. Note that this is just for illustrative purposes and that by default Thwart will respond false to queries which no rules match. 

#### Action groups

To DRY up your configurations, you can define action groups and use them just like actions in rule definitions. See the `action_group :manage` definition at the top and the usage in the `:administrator` role.

#### Role inheritance

To create a role which includes the rules of existing roles, pass the name of the role(s) to the `:include` option of the role definition. __Note__: when a query comes through, it will check the first role passed to `:include` first, and the last last, meaning that the first passed role has the precedence. See 'Query Path' below for more information.

#### Allow / deny blocks

To explicitly deny an actor an action on a resource, you can use `deny` blocks inside the role definition. You can also use `allow` blocks, but this is purely aesthetic.

#### Runtime conditional rules

This is the most powerful and important feature of thwart. Runtime in this sense means the rule can be evaluated under the query conditions, which allows for arbitrarily complex rule definitions. Pass an `:if` option with a proc to any rule definition, and it will be passed the `actor` wishing for authorization, the `resource` being protected, and the `role` the actor is playing. The proc must return one of 3 things:

 1.	True. The rule applies and access is allowed (or denyed if the rule is in a deny block)
 2. False. The rule applies and access is denyed (or allowed if the rule is in an allow block or just the role scope as most roles are)
 3. Nil. The rule does not apply and thwart continues searching up the tree of roles for one that does.

I've found that it's best to return true if you can be certain that the rule applies, and nil otherwise. Returning false is easy to do by accident and can often lead to permission errors where there shouldn't be and confusion.


# Query Path Logging

Thwart has a handy mode where you can log the path of a query you send it for debugging purposes and to analyze your rulesets. By setting `Thwart.log_query_path` to `true` and making a query, a log of the query and the various rules checked will be found at `Thwart.last_query_path`.

# Rails 3 responders

If you use Rails and you want to blanket enforce your thwart rules in your Rails responder enabled controllers, check out the `ThwartedResponder`:

	class ThwartedResponder < ActionController::Responder
	  ActionMap = {:new => :create, :edit => :update}
	  def respond
	    rz = @options[:thwart_resource]
	    rz ||= @resource
	    action = @options[:thwart_action]
	    if controller.action_name == "index"
	      action ||= :show 
	      rz ||= @resource.first.thwart_name if @resource.respond_to?(:first) && @resource.first.respond_to?(:thwart_name)
	    end
	    action ||= controller.action_name.to_sym
	    action = ActionMap[action] if ActionMap.has_key?(action)
	    controller.thwart_access(rz, action)
	    super
	  end
	end
 
Its also a good idea to add a custom exception handler to handler permission errors: 

	class ApplicationController < ActionController::Base
	  include Thwart::Enforcer
	  self.responder = ThwartedResponder
	  rescue_from Thwart::NoPermissionError, :with => :no_permission
	  private
	  # No permission error handler
	  def no_permission(exception)
	    flash[:error] = ("You don't have permission to do that. If you believe this is an error, please contact " + self.class.helpers.mail_to(Settings.administrator_email, 'the administrator')).html_safe
	    redirect_to :root
	  end
	end

# Things thwart does

 * Allows the definition of actions, and groups of actions. Also provides shortcuts to create the common ones.
 * Allows for the definition of "roles", which actors (objects trying to access protected resources) then adopt
 * Allows for the definition of "rules" which relate a role to a resource through either an "allow" or "deny" directive.
 * Allows for role inheritance
 * Allows for clear and advanced query logs

# Things thwart will hopefully do in the future

 * Resource Groups
 * Tightly integrate with the big name ORMs to allow permissions filtered queries. Toughy, but it has been done. Right now if you want to filter records on an index page, you would have to pull them all out and then pop ones out of the array that weren't viewable, which is terribly inefficient and just ruins pagination. 

# Things thwart doesn't do

 * Provide any sort of authentication mechanisms. If you need this I highly recommend Devise.
  
# Usage

thwart draws 

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 Harry Brundage. See LICENSE for details.
