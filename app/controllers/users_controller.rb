class UsersController < ApplicationController
  respond_to :html, :xml, :json
  before_filter :member_only, :only => [:edit, :update, :upgrade]
  rescue_from User::PrivilegeError, :with => "static/access_denied"

  def new
    @user = User.new
    respond_with(@user)
  end
  
  def edit
    @user = User.find(params[:id])
    check_privilege(@user)
    respond_with(@user)
  end
  
  def index
    @search = User.search(params[:search])
    @users = @search.paginate(params[:page]).order("users.name")
    respond_with(@users)
  end
  
  def search
    @search = User.search(params[:search])
  end
  
  def show
    @user = User.find(params[:id])
    @presenter = UserPresenter.new(@user)
    respond_with(@user)
  end
  
  def create
    @user = User.create(params[:user], :as => CurrentUser.role)
    if @user.errors.empty?
      session[:user_id] = @user.id
    end
    set_current_user
    respond_with(@user)
  end
  
  def update
    @user = User.find(params[:id])
    check_privilege(@user)
    @user.update_attributes(params[:user], :as => CurrentUser.role)
    respond_with(@user)
  end
  
  def upgrade
    @user = User.find(params[:id])
    
    if params[:email] =~ /paypal/
      UserMailer.upgrade_fail(params[:email]).deliver
    else
      UserMailer.upgrade(@user, params[:email]).deliver
    end
    
    redirect_to user_path(@user), :notice => "Email was sent"
  end
  
  def cache
    @user = User.find(params[:id])
    @user.update_cache
    render :nothing => true
  end

private
  def check_privilege(user)
    raise User::PrivilegeError unless (user.id == CurrentUser.id || CurrentUser.is_admin?)
  end
end
