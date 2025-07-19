#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include <flutter_linux/fl_method_channel.h>
#include <flutter_linux/fl_standard_method_codec.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <glib.h>

static void log_to_flutter(MyApplication* self,
                           const gchar* level,
                           const gchar* message) {
  if (self->logger_channel == nullptr) return;
  gchar* log = g_strdup_printf("[%s] %s", level, message);
  g_autoptr(FlValue) val = fl_value_new_string(log);
  fl_method_channel_invoke_method(self->logger_channel, "log", val, NULL, NULL, NULL);
  g_free(log);
}

static void run_shell_command(const gchar* command,
                              gboolean returns_bool,
                              FlMethodChannel* channel,
                              FlMethodCall* method_call,
                              MyApplication* self) {
  gchar* stdout_data = NULL;
  gchar* stderr_data = NULL;
  gint exit_status = 0;

  g_autoptr(GError) error = nullptr;
  gboolean success = g_spawn_command_line_sync(command, &stdout_data, &stderr_data,
                                               &exit_status, &error);

  if (!success || error != NULL) {
    g_autoptr(FlValue) details = fl_value_new_string(stderr_data ? stderr_data : "spawn failed");
    g_autoptr(FlMethodResponse) response = fl_method_error_response_new("EXEC_ERROR", "Failed to run", details);
    fl_method_channel_respond(channel, method_call, response, nullptr);
    if (self) log_to_flutter(self, "error", command);
    g_free(stdout_data);
    g_free(stderr_data);
    return;
  }

  if (returns_bool) {
    gboolean is_active = g_strstr_len(stdout_data, -1, "active") != NULL;
    g_autoptr(FlValue) result = fl_value_new_bool(is_active);
    g_autoptr(FlMethodResponse) response = fl_method_success_response_new(result);
    fl_method_channel_respond(channel, method_call, response, nullptr);
    if (self) log_to_flutter(self, "info", command);
  } else {
    g_autoptr(FlValue) result = fl_value_new_string(stdout_data ? stdout_data : "");
    g_autoptr(FlMethodResponse) response = fl_method_success_response_new(result);
    fl_method_channel_respond(channel, method_call, response, nullptr);
    if (self) log_to_flutter(self, "info", stdout_data ? stdout_data : command);
  }

  g_free(stdout_data);
  g_free(stderr_data);
}

// Helper to resolve asset path relative to executable
static gchar* get_asset_path(const gchar* asset_relative) {
  gchar* exe = g_file_read_link("/proc/self/exe", NULL);
  if (exe == NULL) return NULL;
  gchar* dir = g_path_get_dirname(exe);
  gchar* path = g_build_filename(dir, "data", "flutter_assets", asset_relative, NULL);
  g_free(exe);
  g_free(dir);
  return path;
}

static void run_init_xray(FlMethodChannel* channel,
                          FlMethodCall* method_call,
                          MyApplication* self) {
  gchar* service_asset = get_asset_path("assets/xray.service");
  gchar* config_asset = get_asset_path("assets/xray-template.json");
  if (service_asset == NULL || config_asset == NULL) {
    g_autoptr(FlMethodResponse) response =
        fl_method_error_response_new("ASSET_ERROR", "Failed to locate assets", NULL);
    fl_method_channel_respond(channel, method_call, response, nullptr);
    g_free(service_asset);
    g_free(config_asset);
    return;
  }

  gchar* cmd = g_strdup_printf(
      "sudo mkdir -p /etc/xray && sudo cp '%s' /etc/systemd/system/xray.service && "
      "sudo cp '%s' /etc/xray/config.json && sudo systemctl daemon-reload",
      service_asset, config_asset);
  run_shell_command(cmd, FALSE, channel, method_call, self);
  g_free(cmd);
  g_free(service_asset);
  g_free(config_asset);
}

static void handle_native_call(FlMethodChannel* channel,
                               FlMethodCall* method_call,
                               gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  g_autoptr(FlValue) args = fl_method_call_get_args(method_call);
  const gchar* service_name = nullptr;
  if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* val = fl_value_lookup_string(args, "plistName");
    if (val != nullptr && fl_value_get_type(val) == FL_VALUE_TYPE_STRING) {
      service_name = fl_value_get_string(val);
    }
  }

  if (g_strcmp0(method, "startNodeService") == 0 && service_name != NULL) {
    gchar* cmd = g_strdup_printf("sudo systemctl start %s", service_name);
    run_shell_command(cmd, FALSE, channel, method_call, self);
    g_free(cmd);
  } else if (g_strcmp0(method, "stopNodeService") == 0 && service_name != NULL) {
    gchar* cmd = g_strdup_printf("sudo systemctl stop %s", service_name);
    run_shell_command(cmd, FALSE, channel, method_call, self);
    g_free(cmd);
  } else if (g_strcmp0(method, "checkNodeStatus") == 0 && service_name != NULL) {
    gchar* cmd = g_strdup_printf("systemctl is-active %s", service_name);
    run_shell_command(cmd, TRUE, channel, method_call, self);
    g_free(cmd);
  } else if (g_strcmp0(method, "performAction") == 0) {
    const gchar* action = NULL;
    if (args != NULL && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* val = fl_value_lookup_string(args, "action");
      if (val != NULL && fl_value_get_type(val) == FL_VALUE_TYPE_STRING) {
        action = fl_value_get_string(val);
      }
    }
    if (action && g_strcmp0(action, "initXray") == 0) {
      run_init_xray(channel, method_call, self);
    } else {
      g_autoptr(FlMethodResponse) response =
          fl_method_error_response_new("BAD_ACTION", "Unsupported action", NULL);
      fl_method_channel_respond(channel, method_call, response, nullptr);
    }
  } else {
    g_autoptr(FlMethodResponse) response = fl_method_not_implemented_response_new();
    fl_method_channel_respond(channel, method_call, response, nullptr);
  }
}

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* native_channel;
  FlMethodChannel* logger_channel;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "xstream");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "xstream");
  }

  gtk_window_set_default_size(window, 1280, 720);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  FlEngine* engine = fl_view_get_engine(view);
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->native_channel = fl_method_channel_new(messenger, "com.xstream/native", FL_METHOD_CODEC(codec), nullptr, nullptr);
  self->logger_channel = fl_method_channel_new(messenger, "com.xstream/logger", FL_METHOD_CODEC(codec), nullptr, nullptr);
  fl_method_channel_set_method_call_handler(self->native_channel, handle_native_call, g_object_ref(self), g_object_unref);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->native_channel);
  g_clear_object(&self->logger_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {
  self->dart_entrypoint_arguments = nullptr;
  self->native_channel = nullptr;
  self->logger_channel = nullptr;
}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
