---
title: Searching other layers
permalink: /doc/searching-other-layers
parent: Searching the corpus
grand_parent: How to use APLS
nav_order: 40
last_modified_date: 2025-04-12T15:53:35:z
---

# {{ page.title }}
{:.no_toc}

You can search more than just the <span class="layer">orthography</span> layer on the _search_ page.
The first step in doing so is to use the <span class="keyterm">layer picker</span> menu.

{% include page_toc.html collapsible=true %}

## Selecting other layers to search

The <span class="keyterm">layer picker</span> on the _search_ page is similar to the [layer picker on transcript pages]({{ '/doc/view-transcript#layer-selector' | relative_url }}), with some minor differences.[^differences]

[^differences]: The main difference is that transcript pages always have the <span class="layer">word</span>, <span class="layer">turn</span>, and <span class="layer">utterance</span> layers selected and they cannot be de-selected. The _search_ page allows these layers to be toggled on and off.

![]({{ '/assets/screengrab/search/search-layer-selector.png' | relative_url }})

By default, the layer picker has the <span class="layer">orthography</span> layer already selected.
To make more [layers]({{ '/doc/layer-typology' | relative_url }}) appear, you have to select the [project]({{ '/doc/layer-typology#project' | relative_url }}) corresponding with that layer in the `Projects` column.

{: .under-the-hood }
> The <span class="layer">orthography</span>, <span class="layer">word</span>, and <span class="layer">segment</span> layers are displayed without selecting any projects because these layers are not associated with a project.

Selecting a layer in the layer picker will make a [pattern input field]({{ '/doc/your-first-search' | relative_url }}) for that layer appear.

{:.note}
> If you select a layer but don't enter anything into its pattern input field, it doesn't get applied to the search.

The screengrab below has the projects that are most useful to users toggled on to show all the layers that are useful for searching APLS.

![]({{ '/assets/screengrab/search/search-all-layers.png' | relative_url }})

{:.note .no-collapse}
> Layers in the `temp` project aren’t meaningful for end-users, so these layers are not discussed on this page.

Hovering over the names of the layers will display a tooltip giving a brief description of that layer.
For an overview of how layers work in APLS, start with the [Layers and attributes]({{ '/doc/layers-and-attributes' | relative_url }}) documentation section.
In-depth descriptions of the different layers in APLS can be found in the [field guide]({{ '/doc/layer-field-guide' | relative_url }}).

<!-- the apls-dev search page now has more layer icons and the option to hide layer icons -->

### Layer data types and notation systems

Different layers in APLS contain different kinds of annotations.
These differences affect what and how you can search in each layer.

The four data types are:
- Text
- Phonological
- Numeric
- Timing-only

More information about these data types is provided on the [Layer typology]({{ '/doc/layer-typology#data-type' | relative_url }}) documentation page, but for learning how to use the _search_ page it is most useful to simply know that these distinctions exist.

While data type describes the *kinds* of annotation that different layers contain, notation systems are what those annotations actually *look like*.
All layers have a <span class="keyterm">primary notation system</span> (with the exception of timing-only layers because their annotations don't have labels).

The primary notation systems by data type are:
- Text
  - English spelling
  - Treebank part-of-speech tags
  - Boolean (`TRUE` or `FALSE`)
- Phonological
  - DISC phonemic alphabet
  - Stress markers (`'` [primary stress], `"` [secondary stress], `0` [unstressed])
- Numeric
  - Positive whole numbers
  - Decimal numbers
  
You can read more about notation systems on the [Layer typology]({{ '/doc/layer-typology#notation-system' | relative_url }}) and [Layer notation systems]({{ '/doc/layer-notation-systems' | relative_url }}) documentation pages.

Pattern input fields for layers that don't use English spelling or numbers include drop-down selection menus (shown with a ![]({{ '/assets/img/expand-down.svg' | relative_url }}){: style="height:1rem;"} icon) that contain valid input for that layer. 

![]({{ '/assets/screengrab/search/search-dropdown-menu.png' | relative_url }})

![]({{ '/assets/screengrab/search/search-dropdown-menu-expanded.png' | relative_url }})

This saves you the trouble of needing to memorize things like the DISC alphabet or part-of-speech tags to use all of the _search_ page's functionalities!
Similar to other parts of APLS, you can hover your mouse over the options in these drop-down menus to get a short tooltip description for each symbol.

{: .under-the-hood }
> The drop-down menus are displayed as IPA symbols, but they are input into the text fields using the DISC alphabet.
> Because the purpose of DISC is to make phonetic transcription more machine-readable, the only characters that are different from IPA are the ones that aren't found on QWERTY keyboards.

#### Searching text layers...

##### using English spelling

As discussed in [Your first search]({{ '/doc/your-first-search' | relative_url }}), you can search the <span class="layer">orthography</span> layer using English spelling.
Other layers that can be searched using English spelling are:
- <span class="layer">lemma</span> 
- <span class="layer">morphemes</span> 
- <span class="layer">lexical</span> 
- <span class="layer">word</span> 
- <span class="layer">comment</span> 
- <span class="layer">noise</span> 
- <span class="layer">redaction</span>  

{:.note}
> The <span class="layer">redaction</span> search targets the comments that are made for redactions on the word layer.
> All redactions are annotated as `___` on the word layer, which is what appears on the search results page for redactions.
> However, the pattern for <span class="layer">redaction</span> must match the comments in the <span class="layer">redaction</span> layer.
> Therefore, searching for `___` on the <span class="layer">redaction</span> layer won't display any results but searching `.*name.*` will show all redactions that contain "name" in the comment.
  
##### using part-of-speech tags

The only syntax layer in APLS is the <span class="layer">part_of_speech</span> layer, which has a selection menu for accepted part-of-speech tags.

{: .try-it }
> To find matches for every superlative adjective in APLS:
> 1. Go to the [_search_ page](https://apls.pitt.edu/labbcat/search).
> 1. Select the `syntax` project in the layer picker and click the checkbox for the <span class="layer">part_of_speech</span> layer to make the part_of_speech input field appear.
> 1. Click the drop-down menu button (![]({{ '/assets/img/expand-down.svg' | relative_url }}){: style="height:1rem;"}) and select `JJS`.
> 1. Click the _Search_ button.

##### using boolean values (for overlap)

The <span class="layer">overlap</span> layer is part of the [timing project]({{ '/doc/layer-typology#project' | relative_url }}), but it contains text data in the form of Boolean values: `TRUE` for speech that is overlapping and `FALSE` for speech that isn't overlapping. 
The <span class="layer">overlap</span> layer has a drop-down selection menu for these two `TRUE` and `FALSE` values.

#### Searching phonological layers

The phonology layers (and what is included in their drop-down menus) in APLS are:
- <span class="layer">phonemes</span> (IPA symbols that are not on QWERTY keyboards)
- <span class="layer">dictionary_phonemes</span> (IPA symbols that are not on QWERTY keyboards)
- <span class="layer">stress</span> (stress markers)
- <span class="layer">pronounce</span> (IPA symbols that are not on QWERTY keyboards and stress markers)
- <span class="layer">syllables</span> (IPA symbols that are not on QWERTY keyboards and stress markers)

{:.note .no-collapse}
> <span class="layer">segment</span> and <span class="layer">foll_segment</span> layers are similar to the phonological layers in this section, but they have additional capabilities that are described in [Searching segments within words]({{ '/doc/searching-segments-within-words' | relative_url }}).

{: .try-it }
> To find all matches for syllables with /ʊ/ that have secondary stress:
> 1. Go to the [_search_ page](https://apls.pitt.edu/labbcat/search).
> 1. Select the `phonology` layer in the layer picker and click the checkbox for the <span class="layer">syllables</span> layer to make the syllables input field appear.
> 1. Click the drop-down menu button (![]({{ '/assets/img/expand-down.svg' | relative_url }}){: style="height:1rem;"}) and select `secondary` under the `STRESS` heading.
> 1. Enter `.*` after `"` in the syllables input field.
> 1. Click the drop-down menu button (![]({{ '/assets/img/expand-down.svg' | relative_url }}){: style="height:1rem;"}) and select `ʊ` under the `VOWEL` heading.
> 1. Enter `.*` after `".*U` in the sylablles input field.
> 1. Click the _Search_ button.

#### Searching numerical layers

Some layers contain numeric data, instead of text data.
As a result, the pattern input fields for these layers allow you to define a numerical range you would like to search for.

The following layers use numeric range input fields:
- <span class="layer">frequency_from_celex</span> 
- <span class="layer">frequency_in_corpus</span> 
- <span class="layer">speech_rate</span> 
- <span class="layer">foll_pause</span> 

{: .try-it }
> To find every word that only appears in the corpus one to two times:
> 1. Go to the [_search_ page](https://apls.pitt.edu/labbcat/search).
> 1. Select the `lexicon` project in the layer picker and click the checkbox for the <span class="layer">frequency_in_corpus</span> layer to make the frequency_in_corpus input field appear.
> 1. Enter `1` in the frequency_in_corpus _Minimum_ input field and enter `2` in the frequency_in_corpus _Maximum_ input field.
> 1. Click the _Search_ button.
> - This search will include incomplete words as well.
>   To exclude incomplete words, select _doesn't match_ from the _matches_ drop-down menu and enter `.+~` into the orthography input field.
