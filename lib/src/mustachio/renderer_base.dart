// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';
import 'parser.dart';

/// The base class for a generated Mustache renderer.
abstract class RendererBase<T> {
  /// The context object which this renderer can render.
  final T context;

  /// The renderer of the parent context, if any, otherwise `null`.
  final RendererBase parent;

  /// The output buffer into which [context] is rendered, using a template.
  final buffer = StringBuffer();

  RendererBase(this.context, this.parent);

  void write(String text) => buffer.write(text);

  /// Returns the [Property] on this renderer named [name].
  ///
  /// If no property named [name] exists for this renderer, `null` is returned.
  Property getProperty(String key);

  /// Resolves [names] into one or more field accesses, returning the result as
  /// a String.
  ///
  /// [names] may have multiple dot-separate names, and [names] may not be a
  /// valid property of _this_ context type, in which the [parent] renderer is
  /// referenced.
  String getFields(List<String> names) {
    if (names.length == 1 && names.single == '.') {
      return context.toString();
    }
    var property = getProperty(names.first);
    if (property != null) {
      var value = property.getValue(context);
      for (var name in names.skip(1)) {
        if (property.getProperties().containsKey(name)) {
          property = property.getProperties()[name];
          value = property.getValue(value);
        } else {
          throw MustachioResolutionError(
              'Failed to resolve ${names.join('.')} as a property '
              'on ${context.runtimeType}');
        }
      }
      return value.toString();
    } else if (parent != null) {
      return parent.getFields(names);
    } else {
      throw MustachioResolutionError(
          'Failed to resolve ${names.first} as a property '
          'on any types in the current context');
    }
  }

  /// Renders a block of Mustache template, the [ast], into [buffer].
  void renderBlock(List<MustachioNode> ast) {
    for (var node in ast) {
      if (node is Text) {
        write(node.content);
      } else if (node is Variable) {
        var content = getFields(node.key);
        write(content);
      } else if (node is Section) {
        section(node);
      } else if (node is Partial) {
        partial(node);
      }
    }
  }

  void section(Section node) {
    // TODO(srawlins): Implement.
  }

  void partial(Partial node) {
    // TODO(srawlins): Implement.
  }
}

/// An individual property of objects of type [T], including functions for
/// rendering various types of Mustache nodes.
class Property<T> {
  /// Gets the value of this property on the object [context].
  final Object /*?*/ Function(T context) /*!*/ getValue;

  /// Gets the property map of the type of this property.
  final Map<String /*!*/, Property<Object> /*!*/ >
      Function() /*?*/ getProperties;

  /// Gets the bool value (true or false, never null) of this property on the
  /// object [context].
  final bool /*!*/ Function(T context) /*?*/ getBool;

  // TODO(srawlins): Add functions for rendering Iterable properties and other
  // properties.

  Property({@required this.getValue, this.getProperties, this.getBool});
}

/// An error indicating that a renderer failed to resolve a key.
class MustachioResolutionError extends Error {
  String message;

  MustachioResolutionError(this.message);
}