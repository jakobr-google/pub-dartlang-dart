// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

Element tabRoot;
List<Element> tabContents;

void main() {
  tabRoot = document.querySelector('.js-tabs');
  tabContents = document.querySelectorAll('.js-content');
  _setEventsForTabs();
  _setEventForAnchorScroll();
  _setEventForHoverable();
  _setEventForMobileNav();
  _setEventForHashChange();
  _setEventForSearchInput();
  _fixIssueLinks();
  _setEventForSortControl();
}

void _setEventsForTabs() {
  if (tabRoot != null && tabContents.isNotEmpty) {
    tabRoot.onClick.listen((e) {
      // locate the <li> tag
      Element target = e.target;
      while (target != null &&
          target.tagName.toLowerCase() != 'li' &&
          target.tagName.toLowerCase() != 'body') {
        target = target.parent;
      }
      String targetName = target?.dataset['name'];
      if (targetName != null) {
        window.location.hash = '#$targetName';
      }
    });
  }
}

void _setEventForAnchorScroll() {
  document.body.onClick.listen((e) {
    // locate the <a> tag
    Element target = e.target;
    while (target != null &&
        target.tagName.toLowerCase() != 'a' &&
        target.tagName.toLowerCase() != 'body') {
      target = target.parent;
    }
    if (target is AnchorElement &&
        target.getAttribute('href') == target.hash &&
        target.hash != null &&
        target.hash.isNotEmpty) {
      final Element elem = document.querySelector(target.hash);
      if (elem != null) {
        e.preventDefault();
        _scrollTo(elem);
      }
    }
  });
}

/// Elements with the `hoverable` class provide hover tooltip for both desktop
/// browsers and touchscreen devices:
///   - when clicked, they are added a `hover` class (toggled on repeated clicks)
///   - when any outside part is clicked, the `hover` class is removed
///   - when the mouse enters *another* `hoverable` element, the previously
///     active has its style removed
///
///  Their `:hover` and `.hover` style must match to have the same effect.
void _setEventForHoverable() {
  Element activeHover;
  void deactivateHover(_) {
    if (activeHover != null) {
      activeHover.classes.remove('hover');
      activeHover = null;
    }
  }

  document.body.onClick.listen(deactivateHover);

  for (Element h in document.querySelectorAll('.hoverable')) {
    h.onClick.listen((e) {
      if (h != activeHover) {
        deactivateHover(e);
        activeHover = h;
        activeHover.classes.add('hover');
        e.stopPropagation();
      }
    });
    h.onMouseEnter.listen((e) {
      if (h != activeHover) {
        deactivateHover(e);
      }
    });
  }
}

void _setEventForMobileNav() {
  // hamburger menu on mobile
  final Element hamburger = document.querySelector('.hamburger');
  final Element close = document.querySelector('.close');
  final Element mask = document.querySelector('.mask');
  final Element nav = document.querySelector('.nav-wrap');

  hamburger.onClick.listen((_) {
    nav.classes.add('-show');
    mask.classes.add('-show');
  });
  close.onClick.listen((_) {
    nav.classes.remove('-show');
    mask.classes.remove('-show');
  });
  mask.onClick.listen((_) {
    nav.classes.remove('-show');
    mask.classes.remove('-show');
  });
}

void _changeTabOnUrlHash() {
  // change the tab based on URL hash
  if (tabRoot != null && (window.location.hash ?? '').isNotEmpty) {
    _changeTab(window.location.hash.substring(1));
  }
}

void _changeTab(String name) {
  if (tabRoot.querySelector('[data-name=' + name + ']') != null) {
    // toggle tab highlights
    tabRoot.children.forEach((node) {
      if (node.dataset['name'] != name) {
        node.classes.remove('-active');
      } else {
        node.classes.add('-active');
      }
    });
    // toggle content
    tabContents.forEach((node) {
      if (node.dataset['name'] != name) {
        node.classes.remove('-active');
      } else {
        node.classes.add('-active');
      }
    });
  }
}

void _setEventForHashChange() {
  window.onHashChange.listen((_) {
    _changeTabOnUrlHash();
    _fixIssueLinks();
  });
  _changeTabOnUrlHash();
  final String hash = window.location.hash;
  if (hash.isNotEmpty) {
    Element elem = document.querySelector(hash);
    if (elem != null) {
      _scrollTo(elem);
    }
  }
}

Future _scrollTo(Element elem) async {
  final int stepCount = 30;
  final int offsetTop = elem.offsetTop - 24;
  final int scrollY = window.scrollY;
  final int diff = offsetTop - scrollY;
  for (int i = 0; i < stepCount; i++) {
    await window.animationFrame;
    window.scrollTo(window.scrollX, scrollY + diff * (i + 1) ~/ stepCount);
  }
}

void _setEventForSearchInput() {
  final InputElement q = document.querySelector('input[name="q"]');
  if (q == null) return null;
  final List<Element> anchors = document.querySelectorAll('.list-filters > a');
  q.onChange.listen((_) {
    final String newSearchQuery = q.value.trim();
    for (Element a in anchors) {
      final String oldHref = a.getAttribute('href');
      final Uri oldUri = Uri.parse(oldHref);
      final Map params = new Map.from(oldUri.queryParameters);
      params['q'] = newSearchQuery;
      final String newHref = oldUri.replace(queryParameters: params).toString();
      a.setAttribute('href', newHref);
    }
  });
}

void _setEventForSortControl() {
  final Element sortControl = document.getElementById('sort-control');
  final InputElement queryText = document.querySelector('input[name="q"]');
  if (sortControl == null || queryText == null) return;
  final formElement = queryText.form;

  final String originalSort = sortControl.dataset['sort'] ?? '';
  sortControl.innerHtml = '';
  final select = new SelectElement();

  void add(String sort, String label) {
    select.append(new OptionElement(
        value: sort, data: label, selected: originalSort == sort));
  }

  // Synchronize with `template_consts.dart`'s SortDict.
  if (queryText.value.trim().isEmpty) {
    add('listing_relevance', 'listing relevance');
  } else {
    add('search_relevance', 'search relevance');
  }
  add('top', 'overall score');
  add('updated', 'recently updated');
  add('created', 'newest package');
  add('popularity', 'popularity');

  select.onChange.listen((_) {
    final String value = select.selectedOptions.first.value;
    InputElement sortInput = document.querySelector('input[name="sort"]');
    if (sortInput == null) {
      sortInput = new InputElement(type: 'hidden')..name = 'sort';
      queryText.parent.append(sortInput);
    }
    if (value == 'listing_relevance' || value == 'search_relevance') {
      sortInput.remove();
    } else {
      sortInput.value = value;
    }

    // Removes the q= part from the URL
    if (queryText.value.isEmpty) {
      queryText.name = '';
    }

    // TODO: instead of submitting, compose the URL here (also removing the single `?`)
    formElement.submit();
  });
  sortControl.append(select);
}

void _fixIssueLinks() {
  for (AnchorElement bugLink in document.querySelectorAll('a.github_issue')) {
    var url = Uri.parse(bugLink.href);
    final lines = <String>[
      'URL: ${window.location.href}',
      '',
      '<Describe your issue or suggestion here>'
    ];

    final issueLabels = ['Area: site feedback'];

    var bugTitle = '<Summarize your issues here>';
    final bugTag = bugLink.dataset['bugTag'];
    if (bugTag != null) {
      bugTitle = "[$bugTag] $bugTitle";
      if (bugTag == 'analysis') {
        issueLabels.add('Area: package analysis');
      }
    }

    final queryParams = {
      'body': lines.join('\n'),
      'title': bugTitle,
      'labels': issueLabels.join(',')
    };

    url = url.replace(queryParameters: queryParams);
    bugLink.href = url.toString();
  }
}
